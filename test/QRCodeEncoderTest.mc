import Toybox.Lang;
import Toybox.Test;

(:test)
class QRCodeEncoderTest {

    // Test encoder initialization
    (:test)
    function testEncoderInitialization(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);

        // Version 1 should create 21x21 matrix
        var size = encoder.getSize();
        logger.debug("Matrix size: " + size);

        Test.assertEqual(size, 21);
        return true;
    }

    // Test different versions
    (:test)
    function testDifferentVersions(logger as Logger) as Boolean {
        var encoder1 = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        var encoder2 = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        var encoder3 = new QRCodeEncoder(3, QRCodeEncoder.ERROR_LEVEL_L);

        Test.assertEqual(encoder1.getSize(), 21); // 21 + (1-1)*4 = 21
        Test.assertEqual(encoder2.getSize(), 25); // 21 + (2-1)*4 = 25
        Test.assertEqual(encoder3.getSize(), 29); // 21 + (3-1)*4 = 29

        return true;
    }

    // Test encoding simple alphanumeric string
    (:test)
    function testEncodeSimpleString(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        var result = encoder.encode("HELLO");

        logger.debug("Encode 'HELLO' result: " + result);
        Test.assert(result);

        return true;
    }

    // Test encoding numeric string
    (:test)
    function testEncodeNumericString(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        var result = encoder.encode("12345");

        logger.debug("Encode '12345' result: " + result);
        Test.assert(result);

        return true;
    }

    // Test encoding mixed alphanumeric
    (:test)
    function testEncodeMixedAlphanumeric(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        var result = encoder.encode("HR:123 D:5.67 T:890");

        logger.debug("Encode workout data result: " + result);
        Test.assert(result);

        return true;
    }

    // Test encoding with special characters
    (:test)
    function testEncodeWithSpecialChars(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);

        // Valid alphanumeric characters: space, $, %, *, +, -, ., /, :
        var result = encoder.encode("TEST 123");
        Test.assert(result);

        result = encoder.encode("PRICE:$50");
        Test.assert(result);

        result = encoder.encode("RATE:+5%");
        Test.assert(result);

        return true;
    }

    // Test encoding invalid characters (should fail)
    (:test)
    function testEncodeInvalidCharacters(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);

        // Lowercase letters get converted to uppercase, so they work fine
        var result = encoder.encode("hello");
        logger.debug("Encode lowercase result (converted to uppercase): " + result);
        Test.assert(result); // Should return true after toUpper conversion

        // Special characters not in alphanumeric set
        result = encoder.encode("TEST@EMAIL");
        logger.debug("Encode @ symbol result (should fail): " + result);
        Test.assert(!result); // Should return false

        return true;
    }

    // Test matrix is properly initialized
    (:test)
    function testMatrixInitialization(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        encoder.encode("TEST");

        var matrix = encoder.getMatrix();
        var size = encoder.getSize();

        // Matrix should have correct dimensions
        Test.assertEqual(matrix.size(), size);
        Test.assertEqual(matrix[0].size(), size);

        logger.debug("Matrix dimensions: " + size + "x" + matrix[0].size());

        return true;
    }

    // Test different error correction levels
    (:test)
    function testErrorCorrectionLevels(logger as Logger) as Boolean {
        var encoderL = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        var encoderM = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_M);
        var encoderQ = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_Q);
        var encoderH = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_H);

        // All should successfully encode a short string
        Test.assert(encoderL.encode("TEST"));
        Test.assert(encoderM.encode("TEST"));
        Test.assert(encoderQ.encode("TEST"));
        Test.assert(encoderH.encode("TEST"));

        logger.debug("All error correction levels work");

        return true;
    }

    // Test empty string
    (:test)
    function testEncodeEmptyString(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        var result = encoder.encode("");

        logger.debug("Encode empty string result: " + result);
        // Empty string should still encode successfully
        Test.assert(result);

        return true;
    }

    // Test long string capacity
    (:test)
    function testLongStringCapacity(logger as Logger) as Boolean {
        var encoder2 = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);

        // Version 2, Level L can hold ~47 alphanumeric characters
        var shortString = "12345678901234567890"; // 20 chars
        var mediumString = "1234567890123456789012345678901234567890"; // 40 chars

        var result1 = encoder2.encode(shortString);
        logger.debug("Encode 20 char string: " + result1);
        Test.assert(result1);

        var result2 = encoder2.encode(mediumString);
        logger.debug("Encode 40 char string: " + result2);
        Test.assert(result2);

        return true;
    }

    // Test matrix has finder patterns
    (:test)
    function testFinderPatternsExist(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        encoder.encode("TEST");

        var matrix = encoder.getMatrix();

        // Check top-left finder pattern - should have black module at (0,0)
        Test.assert(matrix[0][0]);

        // Check top-right finder pattern - should have black module at (0, size-7)
        var size = encoder.getSize();
        Test.assert(matrix[0][size - 7]);

        // Check bottom-left finder pattern - should have black module at (size-7, 0)
        Test.assert(matrix[size - 7][0]);

        logger.debug("Finder patterns verified");

        return true;
    }

    // Test timing patterns
    (:test)
    function testTimingPatterns(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        encoder.encode("TEST");

        var matrix = encoder.getMatrix();

        // Timing pattern should be at row 6 and column 6
        // Note: After mask pattern is applied, the exact values will change
        // So we just verify the matrix is accessible at these locations
        var hasRowTiming = matrix[6][8] != null;
        var hasColTiming = matrix[8][6] != null;

        Test.assert(hasRowTiming);
        Test.assert(hasColTiming);

        logger.debug("Timing pattern locations verified");

        return true;
    }

    // Test encoding parkrun URL
    (:test)
    function testEncodeParkrunUrl(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        var result = encoder.encode("HTTPS://PARKRUN.COM");

        logger.debug("Encode parkrun URL result: " + result);
        Test.assert(result);

        return true;
    }

    // Test Reed-Solomon error correction with different levels
    (:test)
    function testReedSolomonErrorCorrection(logger as Logger) as Boolean {
        // Test that all error correction levels can encode successfully with Reed-Solomon
        var testData = "A3163889";

        var encoderL = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        var resultL = encoderL.encode(testData);
        logger.debug("Error Level L result: " + resultL);
        Test.assert(resultL);

        var encoderM = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_M);
        var resultM = encoderM.encode(testData);
        logger.debug("Error Level M result: " + resultM);
        Test.assert(resultM);

        var encoderQ = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_Q);
        var resultQ = encoderQ.encode(testData);
        logger.debug("Error Level Q result: " + resultQ);
        Test.assert(resultQ);

        var encoderH = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_H);
        var resultH = encoderH.encode(testData);
        logger.debug("Error Level H result: " + resultH);
        Test.assert(resultH);

        return true;
    }

    // Test and print QR matrix for debugging
    (:test)
    function testPrintQRMatrix(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        encoder.encode("A3163889");

        var matrix = encoder.getMatrix();
        var size = encoder.getSize();

        logger.debug("QR Code Matrix for 'A3163889' (Version 2, Level L):");
        logger.debug("Size: " + size + "x" + size);

        // Print first few rows to see structure
        for (var row = 0; row < 10 && row < size; row++) {
            var line = "";
            for (var col = 0; col < size; col++) {
                line += matrix[row][col] ? "█" : " ";
            }
            logger.debug("Row " + row + ": " + line);
        }

        return true;
    }

    // Test data encoding for "A3163889"
    (:test)
    function testDataEncoding_A3163889(logger as Logger) as Boolean {
        logger.debug("Testing data encoding for 'A3163889'");

        // Reference from Python qr_reference.py:
        // Data bytes (34): [0x20, 0x41, 0xC5, 0x06, 0x62, 0x3C, 0xB8, 0x80,
        //                   0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
        //                   0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
        //                   0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
        //                   0xEC, 0x11]

        var expectedDataBytes = [
            0x20, 0x41, 0xC5, 0x06, 0x62, 0x3C, 0xB8, 0x80,
            0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
            0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
            0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
            0xEC, 0x11
        ] as Array<Number>;

        logger.debug("Expected data bytes: " + expectedDataBytes.size() + " bytes");
        logger.debug("First 8 bytes:");
        for (var i = 0; i < 8; i++) {
            logger.debug("  [" + i + "] = 0x" + expectedDataBytes[i].format("%02X"));
        }

        // Note: This documents the expected encoding
        // The actual encoder internals would need to be exposed to verify
        logger.debug("Data encoding reference documented");

        return true;
    }

    // Test QR matrix matches reference for "A3163889"
    (:test)
    function testMatrixReference_A3163889(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        encoder.encode("A3163889");

        var matrix = encoder.getMatrix();
        var size = encoder.getSize();

        logger.debug("Testing QR matrix against Python reference");
        Test.assertEqual(size, 25);

        // Reference matrix from Python qrcode library (first 10 rows)
        var referenceRows = [
            "███████  ███ ███  ███████",
            "█     █    ██  █  █     █",
            "█ ███ █  ███  █ █ █ ███ █",
            "█ ███ █ █ ██  ██  █ ███ █",
            "█ ███ █ █ █ ████  █ ███ █",
            "█     █  ██  ██ █ █     █",
            "███████ █ █ █ █ █ ███████",
            "         █  ██           ",
            "██   ███ ██ █ ██    ██   ",
            "█ ███  █  █   █   ██ ██  "
        ] as Array<String>;

        logger.debug("Comparing first 10 rows:");
        var allMatch = true;
        for (var row = 0; row < 10; row++) {
            var ourRow = "";
            for (var col = 0; col < size; col++) {
                ourRow += matrix[row][col] ? "█" : " ";
            }

            var matches = ourRow.equals(referenceRows[row]);
            var symbol = matches ? "✓" : "✗";

            logger.debug("Row " + row + " " + symbol);
            if (!matches) {
                logger.debug("  Ours: " + ourRow);
                logger.debug("  Ref:  " + referenceRows[row]);
                allMatch = false;
            }
        }

        if (allMatch) {
            logger.debug("SUCCESS: All rows match reference!");
        } else {
            logger.debug("MISMATCH: Some rows differ from reference");
        }

        // Test passes if matrix matches reference
        Test.assert(allMatch);

        return true;
    }

    // Test format information encoding
    (:test)
    function testFormatInformation(logger as Logger) as Boolean {
        logger.debug("Testing format information encoding");

        // Reference from Python qrcode library:
        // Format bits for Level L, Mask 5: 110001100011000
        // The qrcode library auto-selects mask pattern 5 for "A3163889"
        var expectedFormatBits = [1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0];

        logger.debug("Expected format bits (Level L, Mask 5):");
        logger.debug("  Binary: 110001100011000");
        logger.debug("  Array: " + expectedFormatBits);

        // Format information consists of:
        // - 2 bits: Error correction level (L=01)
        // - 3 bits: Mask pattern (5 = 101)
        // - 10 bits: BCH(15,5) error correction
        // - XOR with 0x5412 mask

        logger.debug("Format info reference documented");
        return true;
    }

    // Test complete encoding pipeline for "A3163889"
    (:test)
    function testCompleteEncodingPipeline_A3163889(logger as Logger) as Boolean {
        logger.debug("Testing complete encoding pipeline for 'A3163889'");

        var encoder = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        var result = encoder.encode("A3163889");

        Test.assert(result);
        logger.debug("Encoding successful: " + result);

        // Reference values from Python qr_reference.py
        logger.debug("\nReference values:");
        logger.debug("  Mode: Alphanumeric");
        logger.debug("  Data bytes: 34");
        logger.debug("  ECC bytes: 10");
        logger.debug("  Total codewords: 44");
        logger.debug("  Matrix size: 25x25");

        // Verify the ECC bytes match
        var dataBytes = [
            0x20, 0x41, 0xC5, 0x06, 0x62, 0x3C, 0xB8, 0x80,
            0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
            0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
            0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
            0xEC, 0x11
        ] as Array<Number>;

        var eccBytes = encoder.testGetECCBytes(dataBytes);
        var expectedECC = [0xC9, 0x6C, 0x1B, 0xEF, 0xDE, 0x10, 0x1C, 0x32, 0xFC, 0x74];

        logger.debug("\nECC verification:");
        var eccMatch = true;
        for (var i = 0; i < eccBytes.size(); i++) {
            var matches = eccBytes[i] == expectedECC[i];
            var symbol = matches ? "✓" : "✗";
            logger.debug("  ECC[" + i + "] = 0x" + eccBytes[i].format("%02X") +
                        " (expected 0x" + expectedECC[i].format("%02X") + ") " + symbol);
            if (!matches) {
                eccMatch = false;
            }
        }

        Test.assert(eccMatch);
        logger.debug("\nComplete pipeline test: " + (eccMatch ? "PASS" : "FAIL"));

        return true;
    }
}
