# Garmin QR Code Library

A highly optimized Monkey C library for generating QR codes on Garmin Connect IQ devices.

## Overview

This library provides efficient QR code generation optimized for the memory and performance constraints of Garmin wearable devices. It generates QR codes that can be rendered directly to the device screen.

## Features

- **Memory Efficient:** Optimized for Garmin's limited memory environment
- **Fast Generation:** Minimal computation and optimized algorithms
- **Compact Code:** Small library footprint
- **Easy to Use:** Simple API for quick integration
- **Flexible Rendering:** Supports various sizes and display options

## Supported QR Code Specifications

- **Versions:** 1-3 (21x21, 25x25, 29x29 modules)
- **Error Correction:** Level L (Low - 7% recovery) and M (Medium - 15% recovery)
- **Encoding Modes:** Byte mode (supports ASCII and binary data)
- **Maximum Capacity:**
  - Version 1 (L): ~17 characters
  - Version 2 (L): ~32 characters
  - Version 3 (L): ~53 characters

## Design Decisions

### Memory Optimization
1. **Bit-Packed Storage:** Uses ByteArray with bit-packing to minimize memory
2. **Pre-computed Tables:** Galois field and error correction tables built at compile time
3. **Minimal Allocations:** Reuses buffers, avoids temporary objects
4. **Compact Data Structures:** Efficient representation of QR matrix

### Performance Optimization
1. **Optimized Reed-Solomon:** Fast error correction code generation
2. **Efficient Masking:** Quick evaluation of mask patterns
3. **Direct Rendering:** Renders directly to device context without intermediate buffers
4. **Lookup Tables:** Pre-computed values for common operations

### Algorithm Overview

```
Input: String data
  ↓
1. Data Analysis
   - Determine best encoding mode
   - Calculate required QR version
   - Validate data length
  ↓
2. Data Encoding
   - Encode data in byte mode
   - Add mode indicator and character count
   - Add terminator and padding
  ↓
3. Error Correction
   - Generate Reed-Solomon error correction codes
   - Interleave data and error correction codewords
  ↓
4. Module Placement
   - Create QR matrix
   - Place function patterns (finders, timing, etc.)
   - Place data bits in zigzag pattern
  ↓
5. Masking
   - Apply best mask pattern
   - Minimize penalty score
  ↓
6. Format Information
   - Add format information bits
   - Apply error correction to format info
  ↓
Output: QR code matrix (bit-packed ByteArray)
```

## API Reference

### QRCode Class

```monkey-c
using Toybox.Graphics;

// Create a QR code encoder
var qr = new QRCode();

// Generate QR code from string
var result = qr.encode(data);
// Returns: {
//   :success => Boolean,
//   :version => Number (1-3),
//   :size => Number (21, 25, or 29),
//   :modules => ByteArray (bit-packed module data)
// } or null on error

// Draw QR code to device context
qr.draw(dc, qrData, x, y, moduleSize);
// dc: Device context
// qrData: Result from encode()
// x, y: Top-left position
// moduleSize: Size of each module in pixels
```

### Methods

**`encode(data)`**
- **Parameters:** `data` (String) - Data to encode
- **Returns:** Dictionary with QR code data or null on failure
- **Description:** Encodes the input string into a QR code matrix

**`draw(dc, qrData, x, y, moduleSize)`**
- **Parameters:**
  - `dc` (Graphics.Dc) - Device context
  - `qrData` (Dictionary) - Result from encode()
  - `x` (Number) - X position (top-left)
  - `y` (Number) - Y position (top-left)
  - `moduleSize` (Number) - Pixel size of each module (default: 2)
- **Returns:** void
- **Description:** Renders the QR code to the device context

**`getMinimumSize(data)`**
- **Parameters:** `data` (String) - Data to encode
- **Returns:** Number - Minimum pixel size needed to display QR code
- **Description:** Calculates minimum display size for the given data

## Usage Example

```monkey-c
using Toybox.Graphics;
using Toybox.WatchUi;

class MyView extends WatchUi.View {
    var qrCode;
    var qrData;

    function initialize() {
        View.initialize();

        // Create QR code instance
        qrCode = new QRCode();

        // Encode data
        qrData = qrCode.encode("Hello Garmin!");

        if (qrData == null) {
            System.println("Failed to encode QR code");
        }
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();

        if (qrData != null) {
            // Center the QR code on screen
            var screenWidth = dc.getWidth();
            var screenHeight = dc.getHeight();
            var moduleSize = 3;
            var qrSize = qrData[:size] * moduleSize;
            var x = (screenWidth - qrSize) / 2;
            var y = (screenHeight - qrSize) / 2;

            // Draw QR code
            qrCode.draw(dc, qrData, x, y, moduleSize);
        }
    }
}
```

## Memory Usage

Approximate memory usage for QR code generation:

- **Version 1 (21x21):** ~100-150 bytes
- **Version 2 (25x25):** ~150-200 bytes
- **Version 3 (29x29):** ~200-250 bytes

Plus fixed overhead of ~500-800 bytes for lookup tables and code.

## Limitations

1. **Maximum Data Length:** Limited to ~53 characters for Version 3
2. **Error Correction:** Only L and M levels supported
3. **Encoding Modes:** Only byte mode supported
4. **QR Versions:** Limited to versions 1-3 for memory efficiency

## Implementation Details

### Bit Packing
Modules are stored in a ByteArray with 8 modules per byte:
```
Byte: [b7 b6 b5 b4 b3 b2 b1 b0]
Each bit represents one module (1=black, 0=white)
```

### Reed-Solomon Error Correction
- Uses Galois Field GF(256) with primitive polynomial 0x11D
- Pre-computed log and antilog tables for fast multiplication
- Generator polynomials pre-computed for each error correction level

### Mask Patterns
Evaluates all 8 mask patterns and selects the one with lowest penalty score:
- Pattern 0: (i + j) % 2 == 0
- Pattern 1: i % 2 == 0
- Pattern 2: j % 3 == 0
- Pattern 3: (i + j) % 3 == 0
- Pattern 4: ((i / 2) + (j / 3)) % 2 == 0
- Pattern 5: ((i * j) % 2) + ((i * j) % 3) == 0
- Pattern 6: (((i * j) % 2) + ((i * j) % 3)) % 2 == 0
- Pattern 7: (((i + j) % 2) + ((i * j) % 3)) % 2 == 0

## Performance Considerations

- **Encoding Time:** ~10-30ms on typical Garmin devices
- **Drawing Time:** ~5-15ms depending on module size and QR version
- **Memory Allocation:** Minimal, uses pre-allocated buffers where possible

## Testing

Test the library with:
1. Short strings (< 10 characters)
2. Medium strings (10-30 characters)
3. Long strings (30-53 characters)
4. Special characters and numbers
5. Different screen sizes and orientations
6. Various module sizes (1-5 pixels)

Verify QR codes with any standard QR code scanner app.

## Future Enhancements

Potential improvements for future versions:
- Support for higher QR versions (4-10)
- Additional error correction levels (Q, H)
- Alphanumeric mode for more efficient encoding
- Numeric mode for number-only data
- Color customization (foreground/background)
- Quiet zone configuration
- Direct BufferedBitmap rendering option

## License

[Your License Here]

## Contributing

[Your Contribution Guidelines Here]

## References

- ISO/IEC 18004:2015 - QR Code specification
- Garmin Connect IQ API Documentation
- Reed-Solomon Error Correction
