import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// QR Code encoder class
// Implements QR code generation with alphanumeric encoding and error correction
class QRCodeEncoder {

    // Error correction levels (static constants)
    static const ERROR_LEVEL_L = 0;
    static const ERROR_LEVEL_M = 1;
    static const ERROR_LEVEL_Q = 2;
    static const ERROR_LEVEL_H = 3;

    // QR Code version (size) - Version 1 = 21x21, Version 2 = 25x25
    private var mVersion as Number;

    // Error correction level (L=7%, M=15%, Q=25%, H=30%)
    private var mErrorLevel as Number;

    // The QR code matrix (2D array of booleans)
    private var mMatrix as Array<Array<Boolean> >;

    // Matrix size
    private var mSize as Number;

    // Function module mask (pre-computed to avoid repeated checks)
    private var mFunctionMask as Array<Array<Boolean> >?;

    // Cached generator polynomial (avoid regenerating for same ECC count)
    private static var sCachedGenerator as Array<Number>?;
    private static var sCachedGeneratorECC as Number = 0;

    // Alphanumeric character set
    private const ALPHANUMERIC_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";

    // Constructor
    // @param version QR code version (1-3 supported)
    // @param errorLevel Error correction level
    function initialize(version as Number, errorLevel as Number) {
        mVersion = version;
        mErrorLevel = errorLevel;
        mSize = 21 + (version - 1) * 4; // Size formula: 21 + (version - 1) * 4
        mFunctionMask = null;

        // Initialize matrix with all false (white)
        mMatrix = new Array<Array<Boolean> >[mSize];
        for (var i = 0; i < mSize; i++) {
            mMatrix[i] = new Array<Boolean>[mSize];
            for (var j = 0; j < mSize; j++) {
                mMatrix[i][j] = false;
            }
        }
    }

    // Encode data into QR code
    // @param data The string to encode
    // @return True if successful, false otherwise
    function encode(data as String) as Boolean {
        System.println("QR: encode() start - data length: " + data.length());

        // Convert to uppercase for alphanumeric mode
        data = data.toUpper();

        // Check if data fits in alphanumeric mode
        if (!isAlphanumeric(data)) {
            System.println("QR: encode() failed - not alphanumeric");
            return false;
        }
        System.println("QR: alphanumeric check passed");

        // Add function patterns FIRST (before data placement)
        System.println("QR: adding finder patterns...");
        addFinderPatterns();
        System.println("QR: adding alignment pattern...");
        addAlignmentPattern();
        System.println("QR: adding timing patterns...");
        addTimingPatterns();
        System.println("QR: adding dark module...");
        addDarkModule();

        // Build function mask ONCE after all function patterns are placed
        System.println("QR: building function mask...");
        buildFunctionMask();
        System.println("QR: function mask complete");

        // Build the data bits
        System.println("QR: building data bits...");
        var bits = buildDataBits(data);
        System.println("QR: data bits complete - " + bits.size() + " bits");

        // Add error correction
        System.println("QR: adding error correction...");
        bits = addErrorCorrection(bits);
        System.println("QR: error correction complete - " + bits.size() + " bits");

        // Place data in matrix (avoiding function patterns)
        System.println("QR: placing data bits in matrix...");
        placeDataBits(bits);
        System.println("QR: data placement complete");

        // Apply mask pattern (only to non-function modules)
        System.println("QR: applying mask pattern...");
        applyBestMask();
        System.println("QR: mask complete");

        // Add format information (goes over mask)
        System.println("QR: adding format info...");
        addFormatInfo();
        System.println("QR: encode() complete");

        return true;
    }

    // Check if string contains only alphanumeric characters
    private function isAlphanumeric(data as String) as Boolean {
        for (var i = 0; i < data.length(); i++) {
            var c = data.substring(i, i + 1);
            if (ALPHANUMERIC_CHARS.find(c) == null) {
                return false;
            }
        }
        return true;
    }

    // Build data bits from input string (pre-allocated for performance)
    private function buildDataBits(data as String) as Array<Boolean> {
        var capacity = getDataCapacity();
        // Pre-allocate array to final size to avoid repeated resizing
        var bits = new Array<Boolean>[capacity];
        var bitIndex = 0;

        // Mode indicator (0010 = alphanumeric)
        bitIndex = addBitsAt(bits, bitIndex, 2, 4);

        // Character count
        var countBits = getCountBits();
        bitIndex = addBitsAt(bits, bitIndex, data.length(), countBits);

        // Encode data in pairs
        for (var i = 0; i < data.length(); i += 2) {
            if (i + 1 < data.length()) {
                // Encode pair
                var val1 = getAlphanumericValue(data.substring(i, i + 1));
                var val2 = getAlphanumericValue(data.substring(i + 1, i + 2));
                bitIndex = addBitsAt(bits, bitIndex, val1 * 45 + val2, 11);
            } else {
                // Encode single character
                var val = getAlphanumericValue(data.substring(i, i + 1));
                bitIndex = addBitsAt(bits, bitIndex, val, 6);
            }
        }

        // Terminator (0000) - up to 4 bits
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

        // Add padding bytes (11101100 and 00010001)
        var padBytes = [236, 17];
        var padIdx = 0;
        while (bitIndex < capacity) {
            bitIndex = addBitsAt(bits, bitIndex, padBytes[padIdx], 8);
            padIdx = (padIdx + 1) % 2;
        }

        return bits;
    }

    // Get alphanumeric value for a character
    private function getAlphanumericValue(c as String) as Number {
        var index = ALPHANUMERIC_CHARS.find(c);
        if (index != null) {
            return index;
        }
        return 0;
    }

    // Add bits to pre-allocated array at specified index, returns new index
    private function addBitsAt(bits as Array<Boolean>, index as Number, value as Number, length as Number) as Number {
        for (var i = length - 1; i >= 0; i--) {
            bits[index] = (value & (1 << i)) != 0;
            index++;
        }
        return index;
    }

    // Get number of bits for character count based on version
    private function getCountBits() as Number {
        if (mVersion <= 9) {
            return 9;
        } else if (mVersion <= 26) {
            return 11;
        } else {
            return 13;
        }
    }

    // Get data capacity in bits for version and error level
    private function getDataCapacity() as Number {
        // Simplified capacity table for Version 1-3, Level L
        var capacities = [
            [152, 272, 440], // Level L
            [128, 224, 352], // Level M
            [104, 176, 272], // Level Q
            [72, 128, 208]   // Level H
        ];
        return capacities[mErrorLevel][mVersion - 1];
    }

    // Galois Field GF(256) log and antilog tables
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

    // Galois Field multiplication
    private function gfMultiply(a as Number, b as Number) as Number {
        if (a == 0 || b == 0) {
            return 0;
        }
        return GF_EXP[(GF_LOG[a] + GF_LOG[b]) % 255];
    }

    // Galois Field division
    private function gfDivide(a as Number, b as Number) as Number {
        if (b == 0) {
            return 0;
        }
        if (a == 0) {
            return 0;
        }
        return GF_EXP[(GF_LOG[a] + 255 - GF_LOG[b]) % 255];
    }

    // Polynomial multiply
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

    // Generate Reed-Solomon generator polynomial (cached for performance)
    private function generateGeneratorPolynomial(numECC as Number) as Array<Number> {
        // Return cached polynomial if available for same ECC count
        if (sCachedGenerator != null && sCachedGeneratorECC == numECC) {
            return sCachedGenerator;
        }

        var gen = [1] as Array<Number>;

        for (var i = 0; i < numECC; i++) {
            var term = [1, GF_EXP[i]] as Array<Number>;
            gen = polyMultiply(gen, term);
        }

        // Cache the result
        sCachedGenerator = gen;
        sCachedGeneratorECC = numECC;

        return gen;
    }

    // Divide polynomials and get remainder
    private function polyDivideRemainder(dividend as Array<Number>, divisor as Array<Number>) as Array<Number> {
        var result = new Array<Number>[dividend.size()];
        for (var i = 0; i < dividend.size(); i++) {
            result[i] = dividend[i];
        }

        for (var i = 0; i < dividend.size() - divisor.size() + 1; i++) {
            var coef = result[i];
            if (coef != 0) {
                for (var j = 1; j < divisor.size(); j++) {
                    if (divisor[j] != 0) {
                        result[i + j] = result[i + j] ^ gfMultiply(divisor[j], coef);
                    }
                }
            }
        }

        // Return remainder (last divisor.size() - 1 terms)
        var remainder = new Array<Number>[divisor.size() - 1];
        for (var i = 0; i < remainder.size(); i++) {
            remainder[i] = result[result.size() - remainder.size() + i];
        }

        return remainder;
    }

    // Get number of error correction codewords
    private function getECCCount() as Number {
        // ECC codewords for versions 1-3 and error levels L, M, Q, H
        var eccTable = [
            [7, 10, 13],   // Level L
            [10, 16, 22],  // Level M
            [13, 22, 28],  // Level Q
            [17, 28, 36]   // Level H
        ];
        return eccTable[mErrorLevel][mVersion - 1];
    }

    // Convert bits to bytes
    private function bitsToBytes(bits as Array<Boolean>) as Array<Number> {
        var bytes = new Array<Number>[bits.size() / 8];
        for (var i = 0; i < bytes.size(); i++) {
            var byte = 0;
            for (var j = 0; j < 8; j++) {
                if (bits[i * 8 + j]) {
                    byte = byte | (1 << (7 - j));
                }
            }
            bytes[i] = byte;
        }
        return bytes;
    }

    // Convert bytes to bits
    private function bytesToBits(bytes as Array<Number>) as Array<Boolean> {
        var bits = new Array<Boolean>[bytes.size() * 8];
        for (var i = 0; i < bytes.size(); i++) {
            for (var j = 0; j < 8; j++) {
                bits[i * 8 + j] = (bytes[i] & (1 << (7 - j))) != 0;
            }
        }
        return bits;
    }

    // Add Reed-Solomon error correction
    private function addErrorCorrection(bits as Array<Boolean>) as Array<Boolean> {
        // Convert bits to bytes
        var dataBytes = bitsToBytes(bits);

        // Get number of error correction codewords
        var numECC = getECCCount();

        // Generate generator polynomial
        var generator = generateGeneratorPolynomial(numECC);

        // Prepare message polynomial (data bytes padded with zeros)
        var message = new Array<Number>[dataBytes.size() + numECC];
        for (var i = 0; i < dataBytes.size(); i++) {
            message[i] = dataBytes[i];
        }
        for (var i = dataBytes.size(); i < message.size(); i++) {
            message[i] = 0;
        }

        // Calculate error correction codewords (remainder of polynomial division)
        var eccBytes = polyDivideRemainder(message, generator);

        // Combine data and error correction bytes
        var allBytes = new Array<Number>[dataBytes.size() + eccBytes.size()];
        for (var i = 0; i < dataBytes.size(); i++) {
            allBytes[i] = dataBytes[i];
        }
        for (var i = 0; i < eccBytes.size(); i++) {
            allBytes[dataBytes.size() + i] = eccBytes[i];
        }

        // Convert back to bits
        return bytesToBits(allBytes);
    }

    // Place data bits in the matrix
    private function placeDataBits(bits as Array<Boolean>) as Void {
        var bitIndex = 0;
        var direction = -1; // -1 = up, 1 = down

        // Start from bottom-right, zigzag upward
        for (var col = mSize - 1; col >= 1; col -= 2) {
            if (col == 6) { col = 5; } // Skip timing column

            for (var i = 0; i < mSize; i++) {
                var row = direction == -1 ? mSize - 1 - i : i;

                for (var c = 0; c < 2; c++) {
                    var x = col - c;

                    // Skip if function pattern
                    if (isFunctionModule(row, x)) {
                        continue;
                    }

                    // Place bit
                    if (bitIndex < bits.size()) {
                        mMatrix[row][x] = bits[bitIndex];
                        bitIndex++;
                    }
                }
            }
            direction = -direction;
        }
    }

    // Check if module is a function pattern (uses pre-computed mask for O(1) lookup)
    private function isFunctionModule(row as Number, col as Number) as Boolean {
        if (mFunctionMask != null) {
            return mFunctionMask[row][col];
        }
        // Fallback to slow path if mask not yet built
        return isFunctionModuleSlow(row, col);
    }

    // Get alignment pattern center position for version 2
    private function getAlignmentPatternCenter() as Number {
        // Alignment pattern centers for versions 2-6
        // Version 2: 6, 18
        // Version 3: 6, 22
        // etc.
        if (mVersion == 2) { return 18; }
        if (mVersion == 3) { return 22; }
        return 0;
    }

    // Add finder patterns to corners
    private function addFinderPatterns() as Void {
        var positions = [[0, 0], [mSize - 7, 0], [0, mSize - 7]];

        for (var p = 0; p < positions.size(); p++) {
            var row = positions[p][0];
            var col = positions[p][1];

            // Outer 7x7 black border
            for (var i = 0; i < 7; i++) {
                for (var j = 0; j < 7; j++) {
                    if (i == 0 || i == 6 || j == 0 || j == 6 ||
                        (i >= 2 && i <= 4 && j >= 2 && j <= 4)) {
                        mMatrix[row + i][col + j] = true;
                    } else {
                        mMatrix[row + i][col + j] = false;
                    }
                }
            }

            // White separator
            for (var i = 0; i < 8; i++) {
                if (row - 1 >= 0 && col + i < mSize) { mMatrix[row - 1][col + i] = false; }
                if (row + 7 < mSize && col + i < mSize) { mMatrix[row + 7][col + i] = false; }
                if (col - 1 >= 0 && row + i < mSize) { mMatrix[row + i][col - 1] = false; }
                if (col + 7 < mSize && row + i < mSize) { mMatrix[row + i][col + 7] = false; }
            }
        }
    }

    // Add alignment pattern (for version 2+)
    private function addAlignmentPattern() as Void {
        if (mVersion < 2) {
            return;
        }

        var center = getAlignmentPatternCenter();
        if (center == 0) {
            return;
        }

        // Draw 5x5 alignment pattern centered at (center, center)
        for (var dr = -2; dr <= 2; dr++) {
            for (var dc = -2; dc <= 2; dc++) {
                var r = center + dr;
                var c = center + dc;
                // Outer ring is black, middle ring white, center is black
                if (dr == -2 || dr == 2 || dc == -2 || dc == 2 || (dr == 0 && dc == 0)) {
                    mMatrix[r][c] = true;
                } else {
                    mMatrix[r][c] = false;
                }
            }
        }
    }

    // Add timing patterns
    private function addTimingPatterns() as Void {
        for (var i = 8; i < mSize - 8; i++) {
            mMatrix[6][i] = (i % 2 == 0);
            mMatrix[i][6] = (i % 2 == 0);
        }
    }

    // Add dark module (always at position (4*version + 9, 8))
    private function addDarkModule() as Void {
        mMatrix[4 * mVersion + 9][8] = true;
    }

    // Build function module mask (pre-compute to avoid repeated checks in O(n²) loops)
    private function buildFunctionMask() as Void {
        mFunctionMask = new Array<Array<Boolean> >[mSize];
        for (var i = 0; i < mSize; i++) {
            mFunctionMask[i] = new Array<Boolean>[mSize];
            for (var j = 0; j < mSize; j++) {
                mFunctionMask[i][j] = isFunctionModuleSlow(i, j);
            }
        }
    }

    // Original function module check (used once to build the mask)
    private function isFunctionModuleSlow(row as Number, col as Number) as Boolean {
        // Finder patterns (3 corners) with separators
        if (row < 9 && col < 9) { return true; } // Top-left
        if (row < 9 && col >= mSize - 8) { return true; } // Top-right
        if (row >= mSize - 8 && col < 9) { return true; } // Bottom-left

        // Timing patterns
        if (row == 6 || col == 6) { return true; }

        // Alignment pattern (for version 2+)
        if (mVersion >= 2) {
            var alignCenter = getAlignmentPatternCenter();
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

    // Mask pattern to use (5 is commonly selected by QR generators)
    private const MASK_PATTERN = 5;

    // Apply mask pattern to data modules
    private function applyBestMask() as Void {
        for (var row = 0; row < mSize; row++) {
            for (var col = 0; col < mSize; col++) {
                if (!isFunctionModule(row, col) && shouldMask(row, col, MASK_PATTERN)) {
                    mMatrix[row][col] = !mMatrix[row][col];
                }
            }
        }
    }

    // Check if a module should be masked based on the mask pattern
    private function shouldMask(row as Number, col as Number, pattern as Number) as Boolean {
        switch (pattern) {
            case 0: return (row + col) % 2 == 0;
            case 1: return row % 2 == 0;
            case 2: return col % 3 == 0;
            case 3: return (row + col) % 3 == 0;
            case 4: return ((row / 2) + (col / 3)) % 2 == 0;
            case 5: return ((row * col) % 2) + ((row * col) % 3) == 0;
            case 6: return (((row * col) % 2) + ((row * col) % 3)) % 2 == 0;
            case 7: return (((row + col) % 2) + ((row * col) % 3)) % 2 == 0;
            default: return false;
        }
    }

    // Generate format information bits
    private function generateFormatBits(errorLevel as Number, maskPattern as Number) as Array<Boolean> {
        // Format information: 5 bits (2 bits ECC level + 3 bits mask pattern) + 10 bits BCH error correction
        // ECC level bits: L=01, M=00, Q=11, H=10
        var eccBits = [
            [0, 1], // Level L
            [0, 0], // Level M
            [1, 1], // Level Q
            [1, 0]  // Level H
        ];

        // Combine ECC level and mask pattern into 5-bit format data
        var formatData = (eccBits[errorLevel][0] << 4) | (eccBits[errorLevel][1] << 3) | maskPattern;

        // Calculate BCH(15,5) error correction for format
        var generator = 0x537; // x^10 + x^8 + x^5 + x^4 + x^2 + x + 1
        var bch = formatData << 10;

        for (var i = 4; i >= 0; i--) {
            if ((bch >> (i + 10)) != 0) {
                bch = bch ^ (generator << i);
            }
        }

        // Combine format data and BCH code
        var formatBits15 = (formatData << 10) | bch;

        // XOR with mask pattern 101010000010010
        formatBits15 = formatBits15 ^ 0x5412;

        // Convert to boolean array
        var formatBits = new Array<Boolean>[15];
        for (var i = 0; i < 15; i++) {
            formatBits[i] = ((formatBits15 >> (14 - i)) & 1) != 0;
        }

        return formatBits;
    }

    // Add format information
    private function addFormatInfo() as Void {
        // Generate format bits for current error level and mask pattern
        var formatBits = generateFormatBits(mErrorLevel, MASK_PATTERN);

        // Place format info around top-left finder pattern
        // Horizontal (row 8, cols 0-5, skip 6, then 7-8)
        for (var i = 0; i < 6; i++) {
            mMatrix[8][i] = formatBits[i];
        }
        mMatrix[8][7] = formatBits[6];  // skip col 6 (timing)
        mMatrix[8][8] = formatBits[7];

        // Vertical (col 8, rows 7, 5, 4, 3, 2, 1, 0) - skip row 6 (timing)
        mMatrix[7][8] = formatBits[8];
        mMatrix[5][8] = formatBits[9];  // skip row 6 (timing)
        mMatrix[4][8] = formatBits[10];
        mMatrix[3][8] = formatBits[11];
        mMatrix[2][8] = formatBits[12];
        mMatrix[1][8] = formatBits[13];
        mMatrix[0][8] = formatBits[14];

        // Place format info around bottom-left finder (vertical, col 8)
        // bits 0-6 at rows (size-1) down to (size-7)
        for (var i = 0; i < 7; i++) {
            mMatrix[mSize - 1 - i][8] = formatBits[i];
        }

        // Place format info around top-right finder (horizontal, row 8)
        // bits 7-14 at cols (size-8) to (size-1)
        for (var i = 0; i < 8; i++) {
            mMatrix[8][mSize - 8 + i] = formatBits[7 + i];
        }
    }

    // Get the QR code matrix
    function getMatrix() as Array<Array<Boolean> > {
        return mMatrix;
    }

    // Get the matrix size
    function getSize() as Number {
        return mSize;
    }

    // Test helper: Generate generator polynomial (exposed for testing)
    function testGenerateGeneratorPolynomial(numECC as Number) as Array<Number> {
        return generateGeneratorPolynomial(numECC);
    }

    // Test helper: Perform polynomial division (exposed for testing)
    function testPolyDivideRemainder(dividend as Array<Number>, divisor as Array<Number>) as Array<Number> {
        return polyDivideRemainder(dividend, divisor);
    }

    // Test helper: GF multiply (exposed for testing)
    function testGfMultiply(a as Number, b as Number) as Number {
        return gfMultiply(a, b);
    }

    // Test helper: Get ECC bytes for data (exposed for testing)
    function testGetECCBytes(dataBytes as Array<Number>) as Array<Number> {
        var numECC = getECCCount();
        var generator = generateGeneratorPolynomial(numECC);

        var message = new Array<Number>[dataBytes.size() + numECC];
        for (var i = 0; i < dataBytes.size(); i++) {
            message[i] = dataBytes[i];
        }
        for (var i = dataBytes.size(); i < message.size(); i++) {
            message[i] = 0;
        }

        return polyDivideRemainder(message, generator);
    }
}
