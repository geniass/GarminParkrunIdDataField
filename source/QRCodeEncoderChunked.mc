import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Callback type for when encoding completes
typedef QREncodeCallback as Method(encoder as QRCodeEncoder?) as Void;

// Chunked QR Code encoder that splits work across timer callbacks
// to avoid watchdog timeout on slow devices
// This is not allowed in data fields annoyingly.
class QRCodeEncoderChunked {

    // Debug logging flag (set to false for production)
    private static const DEBUG = false;

    // Encoding states
    private enum {
        STATE_IDLE,
        STATE_INIT_MATRIX,
        STATE_FINDER_PATTERNS,
        STATE_ALIGNMENT,
        STATE_TIMING,
        STATE_FUNCTION_MASK,
        STATE_BUILD_DATA,
        STATE_ERROR_CORRECTION,
        STATE_PLACE_DATA,
        STATE_APPLY_MASK,
        STATE_FORMAT_INFO,
        STATE_COMPLETE,
        STATE_ERROR
    }

    // Current state
    private var mState as Number;

    // The actual encoder being built
    private var mEncoder as QRCodeEncoder?;

    // Input data
    private var mData as String;
    private var mVersion as Number;
    private var mErrorLevel as Number;

    // Callback when complete
    private var mCallback as QREncodeCallback?;

    // Timer for chunked processing
    private var mTimer as Timer.Timer?;

    // Intermediate data between states
    private var mBits as Array<Boolean>?;

    // Chunk processing state for large loops
    private var mChunkRow as Number;
    private var mChunkIndex as Number;

    // Timer interval in ms (short enough to be responsive, long enough to do work)
    private const TIMER_INTERVAL = 50;

    // Constructor
    function initialize() {
        mState = STATE_IDLE;
        mEncoder = null;
        mData = "";
        mVersion = 2;
        mErrorLevel = QRCodeEncoder.ERROR_LEVEL_L;
        mCallback = null;
        mTimer = null;
        mBits = null;
        mChunkRow = 0;
        mChunkIndex = 0;
    }

    // Start encoding asynchronously
    // @param data The string to encode
    // @param version QR code version (1-3)
    // @param errorLevel Error correction level
    // @param callback Called when encoding completes (with encoder or null on error)
    function startEncode(data as String, version as Number, errorLevel as Number, callback as QREncodeCallback) as Void {
        if (DEBUG) { System.println("QR Chunked: startEncode() - " + data); }

        // Cancel any existing encoding
        stopEncode();

        mData = data.toUpper();
        mVersion = version;
        mErrorLevel = errorLevel;
        mCallback = callback;

        // Validate input
        if (!isAlphanumeric(mData)) {
            if (DEBUG) { System.println("QR Chunked: not alphanumeric, failing"); }
            mState = STATE_ERROR;
            invokeCallback(null);
            return;
        }

        // Create the encoder
        mEncoder = new QRCodeEncoder(mVersion, mErrorLevel);
        mState = STATE_INIT_MATRIX;
        mChunkRow = 0;
        mChunkIndex = 0;

        // Start timer for chunked processing
        mTimer = new Timer.Timer();
        mTimer.start(method(:onTimerTick), TIMER_INTERVAL, true);

        if (DEBUG) { System.println("QR Chunked: timer started"); }
    }

    // Stop encoding (cancel if in progress)
    function stopEncode() as Void {
        if (mTimer != null) {
            mTimer.stop();
            mTimer = null;
        }
        mState = STATE_IDLE;
        mEncoder = null;
        mBits = null;
    }

    // Check if encoding is in progress
    function isEncoding() as Boolean {
        return mState != STATE_IDLE && mState != STATE_COMPLETE && mState != STATE_ERROR;
    }

    // Check if encoding is complete
    function isComplete() as Boolean {
        return mState == STATE_COMPLETE;
    }

    // Get the encoder (only valid after STATE_COMPLETE)
    function getEncoder() as QRCodeEncoder? {
        return mEncoder;
    }

    // Timer callback - process next chunk of work
    function onTimerTick() as Void {
        if (DEBUG) { System.println("QR Chunked: tick - state=" + mState); }

        switch (mState) {
            case STATE_INIT_MATRIX:
                doInitMatrix();
                break;
            case STATE_FINDER_PATTERNS:
                doFinderPatterns();
                break;
            case STATE_ALIGNMENT:
                doAlignment();
                break;
            case STATE_TIMING:
                doTiming();
                break;
            case STATE_FUNCTION_MASK:
                doFunctionMask();
                break;
            case STATE_BUILD_DATA:
                doBuildData();
                break;
            case STATE_ERROR_CORRECTION:
                doErrorCorrection();
                break;
            case STATE_PLACE_DATA:
                doPlaceData();
                break;
            case STATE_APPLY_MASK:
                doApplyMask();
                break;
            case STATE_FORMAT_INFO:
                doFormatInfo();
                break;
            case STATE_COMPLETE:
            case STATE_ERROR:
                // Stop timer and invoke callback
                if (mTimer != null) {
                    mTimer.stop();
                    mTimer = null;
                }
                invokeCallback(mState == STATE_COMPLETE ? mEncoder : null);
                mState = STATE_IDLE;
                break;
        }
    }

    // State handlers - each does a small chunk of work

    private function doInitMatrix() as Void {
        if (DEBUG) { System.println("QR Chunked: init matrix complete"); }
        // Matrix is initialized in constructor, move to next state
        mState = STATE_FINDER_PATTERNS;
    }

    private function doFinderPatterns() as Void {
        if (DEBUG) { System.println("QR Chunked: adding finder patterns"); }
        if (mEncoder != null) {
            // Use internal method via encode step
            addFinderPatternsToEncoder();
        }
        mState = STATE_ALIGNMENT;
    }

    private function doAlignment() as Void {
        if (DEBUG) { System.println("QR Chunked: adding alignment"); }
        if (mEncoder != null) {
            addAlignmentPatternToEncoder();
        }
        mState = STATE_TIMING;
    }

    private function doTiming() as Void {
        if (DEBUG) { System.println("QR Chunked: adding timing"); }
        if (mEncoder != null) {
            addTimingPatternsToEncoder();
            addDarkModuleToEncoder();
        }
        mState = STATE_FUNCTION_MASK;
    }

    private function doFunctionMask() as Void {
        if (DEBUG) { System.println("QR Chunked: building function mask"); }
        if (mEncoder != null) {
            buildFunctionMaskForEncoder();
        }
        mState = STATE_BUILD_DATA;
    }

    private function doBuildData() as Void {
        if (DEBUG) { System.println("QR Chunked: building data bits"); }
        if (mEncoder != null) {
            mBits = buildDataBitsForEncoder();
            if (DEBUG) { System.println("QR Chunked: data bits = " + mBits.size()); }
        }
        mState = STATE_ERROR_CORRECTION;
    }

    private function doErrorCorrection() as Void {
        if (DEBUG) { System.println("QR Chunked: adding error correction"); }
        if (mEncoder != null && mBits != null) {
            mBits = addErrorCorrectionForEncoder(mBits);
            if (DEBUG) { System.println("QR Chunked: with ECC = " + mBits.size()); }
        }
        mState = STATE_PLACE_DATA;
    }

    private function doPlaceData() as Void {
        if (DEBUG) { System.println("QR Chunked: placing data"); }
        if (mEncoder != null && mBits != null) {
            placeDataBitsInEncoder(mBits);
        }
        mState = STATE_APPLY_MASK;
    }

    private function doApplyMask() as Void {
        if (DEBUG) { System.println("QR Chunked: applying mask"); }
        if (mEncoder != null) {
            applyMaskToEncoder();
        }
        mState = STATE_FORMAT_INFO;
    }

    private function doFormatInfo() as Void {
        if (DEBUG) { System.println("QR Chunked: adding format info"); }
        if (mEncoder != null) {
            addFormatInfoToEncoder();
        }
        if (DEBUG) { System.println("QR Chunked: COMPLETE"); }
        mState = STATE_COMPLETE;
    }

    private function invokeCallback(encoder as QRCodeEncoder?) as Void {
        if (mCallback != null) {
            mCallback.invoke(encoder);
        }
        // Request UI update
        WatchUi.requestUpdate();
    }

    // Check if string contains only alphanumeric characters
    private function isAlphanumeric(data as String) as Boolean {
        var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";
        for (var i = 0; i < data.length(); i++) {
            var c = data.substring(i, i + 1);
            if (chars.find(c) == null) {
                return false;
            }
        }
        return true;
    }

    // --- Encoder manipulation functions ---
    // These directly manipulate the encoder's matrix since we can't call private methods

    private function getMatrix() as Array<Array<Boolean> > {
        return mEncoder.getMatrix();
    }

    private function getSize() as Number {
        return mEncoder.getSize();
    }

    private function addFinderPatternsToEncoder() as Void {
        var matrix = getMatrix();
        var size = getSize();
        var positions = [[0, 0], [size - 7, 0], [0, size - 7]];

        for (var p = 0; p < positions.size(); p++) {
            var row = positions[p][0];
            var col = positions[p][1];

            for (var i = 0; i < 7; i++) {
                for (var j = 0; j < 7; j++) {
                    if (i == 0 || i == 6 || j == 0 || j == 6 ||
                        (i >= 2 && i <= 4 && j >= 2 && j <= 4)) {
                        matrix[row + i][col + j] = true;
                    } else {
                        matrix[row + i][col + j] = false;
                    }
                }
            }

            // White separator
            for (var i = 0; i < 8; i++) {
                if (row - 1 >= 0 && col + i < size) { matrix[row - 1][col + i] = false; }
                if (row + 7 < size && col + i < size) { matrix[row + 7][col + i] = false; }
                if (col - 1 >= 0 && row + i < size) { matrix[row + i][col - 1] = false; }
                if (col + 7 < size && row + i < size) { matrix[row + i][col + 7] = false; }
            }
        }
    }

    private function addAlignmentPatternToEncoder() as Void {
        if (mVersion < 2) {
            return;
        }

        var center = 0;
        if (mVersion == 2) { center = 18; }
        else if (mVersion == 3) { center = 22; }

        if (center == 0) {
            return;
        }

        var matrix = getMatrix();

        for (var dr = -2; dr <= 2; dr++) {
            for (var dc = -2; dc <= 2; dc++) {
                var r = center + dr;
                var c = center + dc;
                if (dr == -2 || dr == 2 || dc == -2 || dc == 2 || (dr == 0 && dc == 0)) {
                    matrix[r][c] = true;
                } else {
                    matrix[r][c] = false;
                }
            }
        }
    }

    private function addTimingPatternsToEncoder() as Void {
        var matrix = getMatrix();
        var size = getSize();

        for (var i = 8; i < size - 8; i++) {
            matrix[6][i] = (i % 2 == 0);
            matrix[i][6] = (i % 2 == 0);
        }
    }

    private function addDarkModuleToEncoder() as Void {
        var matrix = getMatrix();
        matrix[4 * mVersion + 9][8] = true;
    }

    // Store function mask separately since encoder's is private
    private var mFunctionMask as Array<Array<Boolean> >?;

    private function buildFunctionMaskForEncoder() as Void {
        var size = getSize();
        mFunctionMask = new Array<Array<Boolean> >[size];
        for (var i = 0; i < size; i++) {
            mFunctionMask[i] = new Array<Boolean>[size];
            for (var j = 0; j < size; j++) {
                mFunctionMask[i][j] = isFunctionModule(i, j);
            }
        }
    }

    private function isFunctionModule(row as Number, col as Number) as Boolean {
        var size = getSize();

        // Finder patterns (3 corners) with separators
        if (row < 9 && col < 9) { return true; }
        if (row < 9 && col >= size - 8) { return true; }
        if (row >= size - 8 && col < 9) { return true; }

        // Timing patterns
        if (row == 6 || col == 6) { return true; }

        // Alignment pattern (for version 2+)
        if (mVersion >= 2) {
            var alignCenter = 0;
            if (mVersion == 2) { alignCenter = 18; }
            else if (mVersion == 3) { alignCenter = 22; }

            if (alignCenter > 0) {
                var dr = row - alignCenter;
                var dc = col - alignCenter;
                if (dr >= -2 && dr <= 2 && dc >= -2 && dc <= 2) {
                    return true;
                }
            }
        }

        return false;
    }

    // Alphanumeric character set
    private const ALPHANUMERIC_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";

    private function getAlphanumericValue(c as String) as Number {
        var index = ALPHANUMERIC_CHARS.find(c);
        if (index != null) {
            return index;
        }
        return 0;
    }

    private function getDataCapacity() as Number {
        var capacities = [
            [152, 272, 440],
            [128, 224, 352],
            [104, 176, 272],
            [72, 128, 208]
        ];
        return capacities[mErrorLevel][mVersion - 1];
    }

    private function getCountBits() as Number {
        if (mVersion <= 9) {
            return 9;
        } else if (mVersion <= 26) {
            return 11;
        } else {
            return 13;
        }
    }

    private function buildDataBitsForEncoder() as Array<Boolean> {
        var capacity = getDataCapacity();
        var bits = new Array<Boolean>[capacity];
        var bitIndex = 0;

        // Mode indicator (0010 = alphanumeric)
        bitIndex = addBitsAt(bits, bitIndex, 2, 4);

        // Character count
        var countBits = getCountBits();
        bitIndex = addBitsAt(bits, bitIndex, mData.length(), countBits);

        // Encode data in pairs
        for (var i = 0; i < mData.length(); i += 2) {
            if (i + 1 < mData.length()) {
                var val1 = getAlphanumericValue(mData.substring(i, i + 1));
                var val2 = getAlphanumericValue(mData.substring(i + 1, i + 2));
                bitIndex = addBitsAt(bits, bitIndex, val1 * 45 + val2, 11);
            } else {
                var val = getAlphanumericValue(mData.substring(i, i + 1));
                bitIndex = addBitsAt(bits, bitIndex, val, 6);
            }
        }

        // Terminator
        var remaining = capacity - bitIndex;
        if (remaining > 4) {
            remaining = 4;
        }
        for (var i = 0; i < remaining; i++) {
            bits[bitIndex] = false;
            bitIndex++;
        }

        // Pad to byte boundary
        while (bitIndex % 8 != 0) {
            bits[bitIndex] = false;
            bitIndex++;
        }

        // Add padding bytes
        var padBytes = [236, 17];
        var padIdx = 0;
        while (bitIndex < capacity) {
            bitIndex = addBitsAt(bits, bitIndex, padBytes[padIdx], 8);
            padIdx = (padIdx + 1) % 2;
        }

        return bits;
    }

    private function addBitsAt(bits as Array<Boolean>, index as Number, value as Number, length as Number) as Number {
        for (var i = length - 1; i >= 0; i--) {
            bits[index] = (value & (1 << i)) != 0;
            index++;
        }
        return index;
    }

    // GF tables (same as QRCodeEncoder)
    private const GF_LOG = [
        0, 0, 1, 25, 2, 50, 26, 198, 3, 223, 51, 238, 27, 104, 199, 75,
        4, 100, 224, 14, 52, 141, 239, 129, 28, 193, 105, 248, 200, 8, 76, 113,
        5, 138, 101, 47, 225, 36, 15, 33, 53, 147, 142, 218, 240, 18, 130, 69,
        29, 181, 194, 125, 106, 39, 249, 185, 201, 154, 9, 120, 77, 228, 114, 166,
        6, 191, 139, 98, 102, 221, 48, 253, 226, 152, 37, 179, 16, 145, 34, 136,
        54, 208, 148, 206, 143, 150, 219, 189, 241, 210, 19, 92, 131, 56, 70, 64,
        30, 66, 182, 163, 195, 72, 126, 110, 107, 58, 40, 84, 250, 133, 186, 61,
        202, 94, 155, 159, 10, 21, 121, 43, 78, 212, 229, 172, 115, 243, 167, 87,
        7, 112, 192, 247, 140, 128, 99, 13, 103, 74, 222, 237, 49, 197, 254, 24,
        227, 165, 153, 119, 38, 184, 180, 124, 17, 68, 146, 217, 35, 32, 137, 46,
        55, 63, 209, 91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190, 97,
        242, 86, 211, 171, 20, 42, 93, 158, 132, 60, 57, 83, 71, 109, 65, 162,
        31, 45, 67, 216, 183, 123, 164, 118, 196, 23, 73, 236, 127, 12, 111, 246,
        108, 161, 59, 82, 41, 157, 85, 170, 251, 96, 134, 177, 187, 204, 62, 90,
        203, 89, 95, 176, 156, 169, 160, 81, 11, 245, 22, 235, 122, 117, 44, 215,
        79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168, 80, 88, 175
    ];

    private const GF_EXP = [
        1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38,
        76, 152, 45, 90, 180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192,
        157, 39, 78, 156, 37, 74, 148, 53, 106, 212, 181, 119, 238, 193, 159, 35,
        70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210, 185, 111, 222, 161,
        95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, 60, 120, 240,
        253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163, 91, 182, 113, 226,
        217, 175, 67, 134, 17, 34, 68, 136, 13, 26, 52, 104, 208, 189, 103, 206,
        129, 31, 62, 124, 248, 237, 199, 147, 59, 118, 236, 197, 151, 51, 102, 204,
        133, 23, 46, 92, 184, 109, 218, 169, 79, 158, 33, 66, 132, 21, 42, 84,
        168, 77, 154, 41, 82, 164, 85, 170, 73, 146, 57, 114, 228, 213, 183, 115,
        230, 209, 191, 99, 198, 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255,
        227, 219, 171, 75, 150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65,
        130, 25, 50, 100, 200, 141, 7, 14, 28, 56, 112, 224, 221, 167, 83, 166,
        81, 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86, 172, 69, 138, 9,
        18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, 22,
        44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, 142, 1
    ];

    private function gfMultiply(a as Number, b as Number) as Number {
        if (a == 0 || b == 0) {
            return 0;
        }
        return GF_EXP[(GF_LOG[a] + GF_LOG[b]) % 255];
    }

    private function getECCCount() as Number {
        var eccTable = [
            [7, 10, 13],
            [10, 16, 22],
            [13, 22, 28],
            [17, 28, 36]
        ];
        return eccTable[mErrorLevel][mVersion - 1];
    }

    // Cached generator polynomial
    private static var sCachedGenerator as Array<Number>?;
    private static var sCachedGeneratorECC as Number = 0;

    private function generateGeneratorPolynomial(numECC as Number) as Array<Number> {
        if (sCachedGenerator != null && sCachedGeneratorECC == numECC) {
            return sCachedGenerator;
        }

        var gen = [1] as Array<Number>;

        for (var i = 0; i < numECC; i++) {
            var term = [1, GF_EXP[i]] as Array<Number>;
            gen = polyMultiply(gen, term);
        }

        sCachedGenerator = gen;
        sCachedGeneratorECC = numECC;

        return gen;
    }

    private function polyMultiply(p1 as Array<Number>, p2 as Array<Number>) as Array<Number> {
        var result = new Array<Number>[p1.size() + p2.size() - 1];
        for (var i = 0; i < result.size(); i++) {
            result[i] = 0;
        }

        for (var i = 0; i < p1.size(); i++) {
            for (var j = 0; j < p2.size(); j++) {
                result[i + j] = result[i + j] ^ gfMultiply(p1[i], p2[j]);
            }
        }

        return result;
    }

    private function addErrorCorrectionForEncoder(bits as Array<Boolean>) as Array<Boolean> {
        // Convert bits to bytes
        var dataBytes = new Array<Number>[bits.size() / 8];
        for (var i = 0; i < dataBytes.size(); i++) {
            var byte = 0;
            for (var j = 0; j < 8; j++) {
                if (bits[i * 8 + j]) {
                    byte = byte | (1 << (7 - j));
                }
            }
            dataBytes[i] = byte;
        }

        var numECC = getECCCount();
        var generator = generateGeneratorPolynomial(numECC);

        // Prepare message polynomial
        var message = new Array<Number>[dataBytes.size() + numECC];
        for (var i = 0; i < dataBytes.size(); i++) {
            message[i] = dataBytes[i];
        }
        for (var i = dataBytes.size(); i < message.size(); i++) {
            message[i] = 0;
        }

        // Polynomial division
        var result = new Array<Number>[message.size()];
        for (var i = 0; i < message.size(); i++) {
            result[i] = message[i];
        }

        for (var i = 0; i < message.size() - generator.size() + 1; i++) {
            var coef = result[i];
            if (coef != 0) {
                for (var j = 1; j < generator.size(); j++) {
                    if (generator[j] != 0) {
                        result[i + j] = result[i + j] ^ gfMultiply(generator[j], coef);
                    }
                }
            }
        }

        // Get remainder (ECC bytes)
        var eccBytes = new Array<Number>[generator.size() - 1];
        for (var i = 0; i < eccBytes.size(); i++) {
            eccBytes[i] = result[result.size() - eccBytes.size() + i];
        }

        // Combine data and ECC
        var allBytes = new Array<Number>[dataBytes.size() + eccBytes.size()];
        for (var i = 0; i < dataBytes.size(); i++) {
            allBytes[i] = dataBytes[i];
        }
        for (var i = 0; i < eccBytes.size(); i++) {
            allBytes[dataBytes.size() + i] = eccBytes[i];
        }

        // Convert back to bits
        var resultBits = new Array<Boolean>[allBytes.size() * 8];
        for (var i = 0; i < allBytes.size(); i++) {
            for (var j = 0; j < 8; j++) {
                resultBits[i * 8 + j] = (allBytes[i] & (1 << (7 - j))) != 0;
            }
        }

        return resultBits;
    }

    private function placeDataBitsInEncoder(bits as Array<Boolean>) as Void {
        var matrix = getMatrix();
        var size = getSize();
        var bitIndex = 0;
        var direction = -1;

        for (var col = size - 1; col >= 1; col -= 2) {
            if (col == 6) { col = 5; }

            for (var i = 0; i < size; i++) {
                var row = direction == -1 ? size - 1 - i : i;

                for (var c = 0; c < 2; c++) {
                    var x = col - c;

                    if (mFunctionMask != null && mFunctionMask[row][x]) {
                        continue;
                    }

                    if (bitIndex < bits.size()) {
                        matrix[row][x] = bits[bitIndex];
                        bitIndex++;
                    }
                }
            }
            direction = -direction;
        }
    }

    private const MASK_PATTERN = 5;

    private function applyMaskToEncoder() as Void {
        var matrix = getMatrix();
        var size = getSize();

        for (var row = 0; row < size; row++) {
            for (var col = 0; col < size; col++) {
                if (mFunctionMask != null && !mFunctionMask[row][col]) {
                    if (shouldMask(row, col)) {
                        matrix[row][col] = !matrix[row][col];
                    }
                }
            }
        }
    }

    private function shouldMask(row as Number, col as Number) as Boolean {
        // Mask pattern 5: ((row * col) % 2) + ((row * col) % 3) == 0
        return ((row * col) % 2) + ((row * col) % 3) == 0;
    }

    private function addFormatInfoToEncoder() as Void {
        var matrix = getMatrix();
        var size = getSize();

        // Generate format bits
        var eccBits = [
            [0, 1], [0, 0], [1, 1], [1, 0]
        ];

        var formatData = (eccBits[mErrorLevel][0] << 4) | (eccBits[mErrorLevel][1] << 3) | MASK_PATTERN;

        var generator = 0x537;
        var bch = formatData << 10;

        for (var i = 4; i >= 0; i--) {
            if ((bch >> (i + 10)) != 0) {
                bch = bch ^ (generator << i);
            }
        }

        var formatBits15 = (formatData << 10) | bch;
        formatBits15 = formatBits15 ^ 0x5412;

        var formatBits = new Array<Boolean>[15];
        for (var i = 0; i < 15; i++) {
            formatBits[i] = ((formatBits15 >> (14 - i)) & 1) != 0;
        }

        // Place format info
        for (var i = 0; i < 6; i++) {
            matrix[8][i] = formatBits[i];
        }
        matrix[8][7] = formatBits[6];
        matrix[8][8] = formatBits[7];

        matrix[7][8] = formatBits[8];
        matrix[5][8] = formatBits[9];
        matrix[4][8] = formatBits[10];
        matrix[3][8] = formatBits[11];
        matrix[2][8] = formatBits[12];
        matrix[1][8] = formatBits[13];
        matrix[0][8] = formatBits[14];

        for (var i = 0; i < 7; i++) {
            matrix[size - 1 - i][8] = formatBits[i];
        }

        for (var i = 0; i < 8; i++) {
            matrix[8][size - 8 + i] = formatBits[7 + i];
        }
    }
}
