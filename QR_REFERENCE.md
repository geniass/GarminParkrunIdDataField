# QR Code Reference Implementation

This document describes the Python reference implementation used for unit testing the Monkey C QR code encoder.

## Overview

The [qr_reference.py](qr_reference.py) script generates reference QR codes and outputs all intermediate steps for comparison with the Monkey C implementation. This ensures correctness at each stage of the encoding pipeline.

## Usage

Run the reference generator:
```bash
uv run qr_reference.py
```

This will output:
- Data encoding (bits and bytes)
- Reed-Solomon error correction codewords
- Format information bits
- Complete QR code matrix
- PNG images for visual verification

## Reference Data for "A3163889"

This is the primary test case used throughout the unit tests.

### Configuration
- **Version:** 2 (25×25 modules)
- **Error Correction:** Level L
- **Mode:** Alphanumeric

### Step 1: Data Encoding

**Data Bytes (34 bytes):**
```
0x20, 0x41, 0xC5, 0x06, 0x62, 0x3C, 0xB8, 0x80,
0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
0xEC, 0x11
```

The encoding process:
1. Mode indicator: `0010` (alphanumeric)
2. Character count: 8 characters (9 bits)
3. Data encoding: Characters encoded in pairs (11 bits per pair)
4. Terminator: Up to 4 zero bits
5. Padding: `0xEC` and `0x11` alternating to fill capacity

### Step 2: Reed-Solomon Error Correction

**Generator Polynomial (10 ECC codewords):**
```
0x01, 0xD8, 0xC2, 0x9F, 0x6F, 0xC7, 0x5E, 0x5F, 0x71, 0x9D, 0xC1
```

**ECC Bytes (10 bytes):**
```
0xC9, 0x6C, 0x1B, 0xEF, 0xDE, 0x10, 0x1C, 0x32, 0xFC, 0x74
```

**Complete Codeword Sequence (44 bytes):**
Data bytes (34) + ECC bytes (10)

### Step 3: Format Information

**Format Bits (Level L, Mask 0):**
- Hex: `0x77C4`
- Binary: `111011111000100`
- Array: `[1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0]`

Format information encoding:
1. Error correction level: `01` (L)
2. Mask pattern: `000` (mask 0)
3. BCH(15,5) error correction: 10 bits
4. XOR with mask: `0x5412`

### Step 4: QR Matrix

**First 10 rows (25×25 matrix):**
```
Row  0: ███████  ███ ███  ███████
Row  1: █     █    ██  █  █     █
Row  2: █ ███ █  ███  █ █ █ ███ █
Row  3: █ ███ █ █ ██  ██  █ ███ █
Row  4: █ ███ █ █ █ ████  █ ███ █
Row  5: █     █  ██  ██ █ █     █
Row  6: ███████ █ █ █ █ █ ███████
Row  7:          █  ██
Row  8: ██   ███ ██ █ ██    ██
Row  9: █ ███  █  █   █   ██ ██
```

## Unit Tests

The reference data is hardcoded in the following test files:

### [test/QRCodeEncoderTest.mc](test/QRCodeEncoderTest.mc)

Tests that verify:
- Data encoding for "A3163889"
- QR matrix matches reference (10 rows)
- Format information encoding
- Complete encoding pipeline

Key test: `testMatrixReference_A3163889()` compares the generated matrix against the reference row-by-row.

### [test/ReedSolomonTest.mc](test/ReedSolomonTest.mc)

Tests that verify:
- Galois Field multiplication
- Generator polynomial generation
- Reed-Solomon ECC byte generation
- Polynomial division
- Complete matrix comparison

Key test: `testReedSolomonECC_A3163889()` verifies all 10 ECC bytes match exactly.

## Data Placement Algorithm

The QR code data placement follows the standard algorithm:
1. Start at bottom-right corner
2. Place data in 2-column vertical strips, moving upward
3. Skip timing patterns and function patterns (finders, alignment, etc.)
4. Reverse direction when reaching top/bottom edges
5. Continue until all data and ECC codewords are placed

## Mask Pattern Application

After data placement, mask pattern 0 is applied to data modules:
- Mask 0 formula: `(row + col) % 2 == 0`
- Only data modules are masked (not function patterns)
- XOR operation inverts modules where mask formula is true

## Verification

To verify the Monkey C implementation:

1. **Run the Python reference:**
   ```bash
   uv run qr_reference.py
   ```

2. **Build and test:**
   ```bash
   make build
   make test
   ```

3. **Visual verification:**
   The Python script generates PNG images that can be scanned with a phone to verify they decode correctly.

## Key Implementation Notes

1. **Galois Field arithmetic** uses log/exp tables for multiplication
2. **Generator polynomial** is constructed iteratively for each ECC count
3. **Data encoding** uses alphanumeric mode for A-Z, 0-9, and special chars
4. **Padding bytes** alternate between `0xEC` and `0x11`
5. **Format information** uses BCH(15,5) error correction and is XORed with `0x5412`

## References

- ISO/IEC 18004:2015 - QR Code specification
- [qrcode Python library](https://github.com/lincolnloop/python-qrcode)
- [QR Code Tutorial](https://www.thonky.com/qr-code-tutorial/)
