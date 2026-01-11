#!/usr/bin/env python3
"""
QR Code Reference Implementation
Generates QR code for "A3163889" and outputs all intermediate steps
for comparison with Monkey C implementation.
"""
# /// script
# dependencies = [
#   "qrcode[pil]",
# ]
# ///

import qrcode
from qrcode.main import QRCode
import qrcode.constants

def generate_reference_qr():
    """Generate reference QR code and return all intermediate data"""

    # Create QR code
    qr = QRCode(
        version=2,  # Version 2 (25x25)
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=1,
        border=0,
    )

    qr.add_data("A3163889")
    qr.make(fit=False)

    matrix = qr.get_matrix()

    return {
        'version': 2,
        'error_level': 'L',
        'data': 'A3163889',
        'matrix_size': len(matrix),
        'matrix': matrix
    }

def encode_data_bits():
    """Encode data bits for 'A3163889' in alphanumeric mode"""
    chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
    data = "A3163889"

    bits = []

    # Mode indicator: 0010 (alphanumeric)
    bits.extend([0, 0, 1, 0])

    # Character count (9 bits for version 2)
    count = len(data)
    for i in range(8, -1, -1):
        bits.append((count >> i) & 1)

    # Encode data in pairs
    for i in range(0, len(data), 2):
        if i + 1 < len(data):
            val1 = chars.index(data[i])
            val2 = chars.index(data[i+1])
            value = val1 * 45 + val2
            for j in range(10, -1, -1):
                bits.append((value >> j) & 1)
        else:
            val = chars.index(data[i])
            for j in range(5, -1, -1):
                bits.append((val >> j) & 1)

    # Terminator (up to 4 zero bits)
    data_capacity_bits = 272
    remaining = data_capacity_bits - len(bits)
    terminator_bits = min(4, remaining)
    bits.extend([0] * terminator_bits)

    # Pad to byte boundary
    while len(bits) % 8 != 0:
        bits.append(0)

    # Add padding bytes
    pad_bytes = [236, 17]
    pad_index = 0
    while len(bits) < data_capacity_bits:
        byte = pad_bytes[pad_index]
        for i in range(7, -1, -1):
            bits.append((byte >> i) & 1)
        pad_index = (pad_index + 1) % 2

    # Convert to bytes
    data_bytes = []
    for i in range(0, len(bits), 8):
        byte = 0
        for j in range(8):
            if bits[i + j]:
                byte |= (1 << (7 - j))
        data_bytes.append(byte)

    return {
        'bits': bits,
        'bytes': data_bytes,
        'num_bits': len(bits),
        'num_bytes': len(data_bytes)
    }

def calculate_reed_solomon():
    """Calculate Reed-Solomon ECC bytes"""
    GF_LOG = [0, 0, 1, 25, 2, 50, 26, 198, 3, 223, 51, 238, 27, 104, 199, 75, 4, 100, 224, 14, 52, 141, 239, 129, 28, 193, 105, 248, 200, 8, 76, 113, 5, 138, 101, 47, 225, 36, 15, 33, 53, 147, 142, 218, 240, 18, 130, 69, 29, 181, 194, 125, 106, 39, 249, 185, 201, 154, 9, 120, 77, 228, 114, 166, 6, 191, 139, 98, 102, 221, 48, 253, 226, 152, 37, 179, 16, 145, 34, 136, 54, 208, 148, 206, 143, 150, 219, 189, 241, 210, 19, 92, 131, 56, 70, 64, 30, 66, 182, 163, 195, 72, 126, 110, 107, 58, 40, 84, 250, 133, 186, 61, 202, 94, 155, 159, 10, 21, 121, 43, 78, 212, 229, 172, 115, 243, 167, 87, 7, 112, 192, 247, 140, 128, 99, 13, 103, 74, 222, 237, 49, 197, 254, 24, 227, 165, 153, 119, 38, 184, 180, 124, 17, 68, 146, 217, 35, 32, 137, 46, 55, 63, 209, 91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190, 97, 242, 86, 211, 171, 20, 42, 93, 158, 132, 60, 57, 83, 71, 109, 65, 162, 31, 45, 67, 216, 183, 123, 164, 118, 196, 23, 73, 236, 127, 12, 111, 246, 108, 161, 59, 82, 41, 157, 85, 170, 251, 96, 134, 177, 187, 204, 62, 90, 203, 89, 95, 176, 156, 169, 160, 81, 11, 245, 22, 235, 122, 117, 44, 215, 79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168, 80, 88, 175]

    GF_EXP = [1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38, 76, 152, 45, 90, 180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192, 157, 39, 78, 156, 37, 74, 148, 53, 106, 212, 181, 119, 238, 193, 159, 35, 70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210, 185, 111, 222, 161, 95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, 60, 120, 240, 253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163, 91, 182, 113, 226, 217, 175, 67, 134, 17, 34, 68, 136, 13, 26, 52, 104, 208, 189, 103, 206, 129, 31, 62, 124, 248, 237, 199, 147, 59, 118, 236, 197, 151, 51, 102, 204, 133, 23, 46, 92, 184, 109, 218, 169, 79, 158, 33, 66, 132, 21, 42, 84, 168, 77, 154, 41, 82, 164, 85, 170, 73, 146, 57, 114, 228, 213, 183, 115, 230, 209, 191, 99, 198, 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 227, 219, 171, 75, 150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65, 130, 25, 50, 100, 200, 141, 7, 14, 28, 56, 112, 224, 221, 167, 83, 166, 81, 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86, 172, 69, 138, 9, 18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, 22, 44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, 142, 1]

    def gf_multiply(a, b):
        if a == 0 or b == 0:
            return 0
        return GF_EXP[(GF_LOG[a] + GF_LOG[b]) % 255]

    def poly_multiply(p1, p2):
        result = [0] * (len(p1) + len(p2) - 1)
        for i in range(len(p1)):
            for j in range(len(p2)):
                result[i + j] ^= gf_multiply(p1[i], p2[j])
        return result

    def generate_generator_polynomial(num_ecc):
        gen = [1]
        for i in range(num_ecc):
            term = [1, GF_EXP[i]]
            gen = poly_multiply(gen, term)
        return gen

    def poly_divide_remainder(dividend, divisor):
        result = dividend[:]
        for i in range(len(dividend) - len(divisor) + 1):
            coef = result[i]
            if coef != 0:
                for j in range(1, len(divisor)):
                    if divisor[j] != 0:
                        result[i + j] ^= gf_multiply(divisor[j], coef)
        return result[-(len(divisor) - 1):]

    # Data bytes
    data_bytes = [
        0x20, 0x41, 0xC5, 0x06, 0x62, 0x3C, 0xB8, 0x80,
        0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
        0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
        0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
        0xEC, 0x11
    ]

    num_ecc = 10
    generator = generate_generator_polynomial(num_ecc)
    message = data_bytes + [0] * num_ecc
    ecc_bytes = poly_divide_remainder(message, generator)

    return {
        'generator_polynomial': generator,
        'data_bytes': data_bytes,
        'ecc_bytes': ecc_bytes,
        'complete_codeword': data_bytes + ecc_bytes
    }

def calculate_format_info():
    """Calculate format information for Level L, Mask 5 (auto-selected by qrcode lib)"""
    # ECC level bits: L=01, M=00, Q=11, H=10
    ecc_level = 0  # L
    mask_pattern = 5  # qrcode library auto-selects mask 5 for "A3163889"

    ecc_bits_map = {
        0: [0, 1],  # L
        1: [0, 0],  # M
        2: [1, 1],  # Q
        3: [1, 0]   # H
    }

    ecc_bits = ecc_bits_map[ecc_level]

    # Combine ECC level and mask pattern into 5-bit format data
    format_data = (ecc_bits[0] << 4) | (ecc_bits[1] << 3) | mask_pattern

    # Calculate BCH(15,5) error correction
    generator = 0x537
    bch = format_data << 10

    for i in range(4, -1, -1):
        if (bch >> (i + 10)) != 0:
            bch = bch ^ (generator << i)

    # Combine format data and BCH code
    format_bits_15 = (format_data << 10) | bch

    # XOR with mask pattern
    format_bits_15 = format_bits_15 ^ 0x5412

    # Convert to array
    format_bits = []
    for i in range(15):
        format_bits.append((format_bits_15 >> (14 - i)) & 1)

    return {
        'format_data': format_data,
        'format_bits_15': format_bits_15,
        'format_bits': format_bits,
        'format_hex': f"0x{format_bits_15:04X}",
        'format_binary': f"{format_bits_15:015b}"
    }

def main():
    print("=" * 70)
    print("QR CODE REFERENCE IMPLEMENTATION")
    print("Data: 'A3163889'")
    print("Version: 2 (25x25)")
    print("Error Correction: Level L")
    print("=" * 70)
    print()

    # Step 1: Data encoding
    print("STEP 1: DATA ENCODING")
    print("-" * 70)
    data_info = encode_data_bits()
    print(f"Data bits: {data_info['num_bits']}")
    print(f"Data bytes: {data_info['num_bytes']}")
    print("\nData bytes (hex):")
    for i, byte in enumerate(data_info['bytes']):
        if i % 16 == 0:
            print()
            print(f"  ", end="")
        print(f"{byte:02X} ", end="")
    print("\n")

    # Step 2: Reed-Solomon ECC
    print("\nSTEP 2: REED-SOLOMON ERROR CORRECTION")
    print("-" * 70)
    rs_info = calculate_reed_solomon()
    print(f"Generator polynomial ({len(rs_info['generator_polynomial'])} coefficients):")
    print("  ", end="")
    for coef in rs_info['generator_polynomial']:
        print(f"{coef:02X} ", end="")
    print()
    print(f"\nECC bytes ({len(rs_info['ecc_bytes'])} bytes):")
    print("  ", end="")
    for byte in rs_info['ecc_bytes']:
        print(f"{byte:02X} ", end="")
    print()
    print(f"\nComplete codeword ({len(rs_info['complete_codeword'])} bytes):")
    for i, byte in enumerate(rs_info['complete_codeword']):
        if i % 16 == 0:
            print()
            print(f"  ", end="")
        if i == len(rs_info['data_bytes']):
            print("| ", end="")
        print(f"{byte:02X} ", end="")
    print("\n")

    # Step 3: Format information
    print("\nSTEP 3: FORMAT INFORMATION")
    print("-" * 70)
    format_info = calculate_format_info()
    print(f"Format data: {format_info['format_data']:02X}")
    print(f"Format bits (15-bit): {format_info['format_hex']}")
    print(f"Format bits (binary): {format_info['format_binary']}")
    print(f"Format bits array: {format_info['format_bits']}")
    print()

    # Step 4: Reference QR matrix
    print("\nSTEP 4: REFERENCE QR MATRIX")
    print("-" * 70)
    ref_qr = generate_reference_qr()
    print(f"Matrix size: {ref_qr['matrix_size']}x{ref_qr['matrix_size']}")
    print("\nAll 25 rows:")
    for i in range(ref_qr['matrix_size']):
        row = ""
        for j in range(ref_qr['matrix_size']):
            row += "█" if ref_qr['matrix'][i][j] else " "
        print(f"  Row {i:2d}: {row}")
    print()

    # Save image
    qr = QRCode(version=2, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=10, border=4)
    qr.add_data("A3163889")
    qr.make(fit=False)
    img = qr.make_image(fill_color="black", back_color="white")
    output_path = "/tmp/reference_qr_A3163889.png"
    img.save(output_path)
    print(f"Reference QR code image saved to: {output_path}")
    print("Scan this with your phone to verify it works!")
    print()

    # Summary for unit tests
    print("\n" + "=" * 70)
    print("REFERENCE VALUES FOR UNIT TESTS")
    print("=" * 70)
    print(f"\nData bytes ({len(data_info['bytes'])}): {[f'0x{b:02X}' for b in data_info['bytes']]}")
    print(f"\nECC bytes ({len(rs_info['ecc_bytes'])}): {[f'0x{b:02X}' for b in rs_info['ecc_bytes']]}")
    print(f"\nGenerator polynomial: {[f'0x{b:02X}' for b in rs_info['generator_polynomial']]}")
    print(f"\nFormat bits (0x{format_info['format_bits_15']:04X}): {format_info['format_bits']}")

if __name__ == "__main__":
    main()
