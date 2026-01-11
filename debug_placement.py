#!/usr/bin/env python3
"""Debug data placement algorithm by tracing where bits should go"""
# /// script
# dependencies = []
# ///

SIZE = 25
ALIGN_CENTER = 18  # Version 2 alignment pattern center

def is_function_module(row, col):
    """Check if module is a function pattern"""
    # Finder patterns (3 corners) with separators
    if row < 9 and col < 9:
        return True  # Top-left
    if row < 9 and col >= SIZE - 8:
        return True  # Top-right
    if row >= SIZE - 8 and col < 9:
        return True  # Bottom-left

    # Timing patterns
    if row == 6 or col == 6:
        return True

    # Alignment pattern (5x5 centered at 18,18)
    if abs(row - ALIGN_CENTER) <= 2 and abs(col - ALIGN_CENTER) <= 2:
        return True

    return False

# Simulate data placement
bit_positions = []
direction = -1  # -1 = up, 1 = down

col = SIZE - 1
while col >= 1:
    if col == 6:
        col = 5  # Skip timing column

    for i in range(SIZE):
        row = SIZE - 1 - i if direction == -1 else i

        for c in range(2):
            x = col - c

            if not is_function_module(row, x):
                bit_positions.append((row, x))

    direction = -direction
    col -= 2

print(f"Total bit positions: {len(bit_positions)}")
print(f"Expected for V2-L: 44 bytes * 8 = 352 bits")

# Print first 20 bit positions
print("\nFirst 20 bit positions (row, col):")
for i, (r, c) in enumerate(bit_positions[:20]):
    print(f"  Bit {i}: ({r}, {c})")

# Print last 20 bit positions
print(f"\nLast 20 bit positions (bit index from {len(bit_positions)-20}):")
for i, (r, c) in enumerate(bit_positions[-20:]):
    print(f"  Bit {len(bit_positions)-20+i}: ({r}, {c})")
