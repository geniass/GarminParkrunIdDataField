# Monkey C Programming Guide

## Overview
Monkey C is Garmin's proprietary programming language for the Connect IQ platform, used to develop apps, watch faces, and data fields for Garmin wearable devices.

## Core Language Features

### Data Types
**Basic Types:**
- `Number` - Integer number type
- `Long` - Long integer
- `Float` - Floating point number
- `Double` - Double precision float
- `String` - Text string
- `Char` - Single character
- `Boolean` - true/false values

**Collection Types:**
- `Array` - Ordered collection with indexed access
- `Dictionary` - Key-value pair storage
- `ByteArray` - Binary data storage

**Type Aliases:**
- `Integer` - Number or Long
- `Decimal` - Float or Double
- `Numeric` - Number, Float, Long, or Double

**Specialized Types:**
- `Symbol` - Symbolic identifiers
- `ResourceId` - Resource references
- `WeakReference` - Weak object references
- `Method` - Method references

### Syntax

**Module/Namespace System:**
- Core APIs in `Toybox` namespace
- Import with `using Toybox.Graphics;`
- Access with `Toybox.Graphics.Dc`

**String Formatting:**
- Use `$1$`, `$2$` syntax for parameter substitution
- Example: `Lang.format("Value: $1$", [value])`

**Classes:**
- Object-oriented with class definitions
- Support inheritance and interfaces

### Exception Handling
Available exceptions:
- `InvalidOptionsException`
- `InvalidValueException`
- `OperationNotAllowedException`
- `UnexpectedTypeException`
- `ValueOutOfBoundsException`
- `StorageFullException`
- `SerializationException`

## Graphics Module (Toybox.Graphics)

### Device Context (Dc)
The Device Context is the primary drawing interface for rendering graphics.

**Key Classes:**
- `Dc` - Device Context for all drawing operations
- `BufferedBitmap` - Off-screen rendering surface
- `BufferedBitmapReference` - Reference to buffered bitmap
- `BitmapReference` - Reference to bitmap resources
- `VectorFont` - Scalable fonts
- `FontReference` - Font resource references

### Colors

**Predefined Colors:**
- `COLOR_WHITE`, `COLOR_BLACK`
- `COLOR_RED`, `COLOR_BLUE`, `COLOR_GREEN`
- `COLOR_YELLOW`, `COLOR_ORANGE`, `COLOR_PURPLE`, `COLOR_PINK`
- `COLOR_LT_GRAY`, `COLOR_DK_GRAY`
- `COLOR_TRANSPARENT` (-1)

**Custom Colors:**
```
Graphics.createColor(alpha, red, green, blue)
// alpha, red, green, blue: 0-255
// Returns 32-bit color value
```

### Drawing Methods

**Shapes & Lines:**
- Draw and fill various shapes
- Line rendering
- Arc drawing (clockwise/counter-clockwise)

**Text Rendering:**
- Multiple font sizes (XTINY to LARGE)
- System fonts, number fonts, glance fonts
- Vector fonts with custom sizing
- Text justification: LEFT, CENTER, RIGHT, VCENTER
- `getFontHeight()`, `getFontAscent()`, `getFontDescent()`
- `fitTextToArea()` - Fit text with optional truncation

**Radial Text:**
- `CLOCKWISE` - Top of text away from center
- `COUNTER_CLOCKWISE` - Bottom of text away from center

### Buffered Bitmaps

**Creating:**
```
Graphics.createBufferedBitmap({
    :width => width,      // positive integer
    :height => height,    // positive integer
    :palette => colors,   // array of colors (max 256)
    :bitsPerPixel => bpp, // color depth
    :alphaBlending => Graphics.ALPHA_BLENDING_FULL
});
```

**Alpha Blending Modes:**
- `ALPHA_BLENDING_FULL` - Full alpha support
- `ALPHA_BLENDING_PARTIAL` - Partial alpha
- `SOURCE_OVER` - Standard composition (default)
- `SOURCE` - No blending
- `MULTIPLY` - Multiplicative (GPU required)
- `ADDITIVE` - Additive (GPU required)

**Filter Modes:**
- `FILTER_MODE_POINT` - Single-pixel sampling
- `FILTER_MODE_BILINEAR` - Multi-pixel interpolation

## Memory Management

**Critical Constraints:**
- Garmin devices have very limited memory
- Minimize allocations during runtime
- Pre-allocate arrays where possible
- Use efficient data structures
- Avoid creating unnecessary objects
- Consider using ByteArray for binary data

**Optimization Tips:**
1. Reuse objects instead of creating new ones
2. Use primitive types over objects when possible
3. Minimize array copying
4. Use bit operations for compact data storage
5. Profile memory usage regularly

## Performance Best Practices

1. **Minimize Drawing Operations:**
   - Batch drawing calls
   - Use BufferedBitmap for complex graphics
   - Draw only what changed

2. **Efficient Data Structures:**
   - Use ByteArray for binary data
   - Pack bits for boolean arrays
   - Use appropriate numeric types (Number vs Long)

3. **Algorithm Optimization:**
   - Pre-compute values when possible
   - Use lookup tables for repeated calculations
   - Minimize loops and iterations

4. **Memory Efficiency:**
   - Avoid creating temporary objects in loops
   - Reuse buffers and arrays
   - Clear references when done

## Module System

**Core Modules (Toybox namespace):**
- `Graphics` - Drawing and rendering
- `WatchUi` - UI components and screens
- `System` - Device-level operations
- `Lang` - Core language features
- `Math` - Mathematical operations
- `StringUtil` - String utilities
- `Time` / `Timer` - Time management
- ~30+ other specialized modules

## Number Formats
Support for various binary formats:
- 8/16/32-bit signed/unsigned integers
- 32-bit floats
- Little-endian and big-endian byte ordering

## Key Differences from Other Languages

1. **Memory Constraints:** Much more limited than desktop/mobile
2. **Namespace System:** Uses Toybox namespace for all APIs
3. **Resource-Based:** Heavy use of resources and resource IDs
4. **Device Context:** All drawing goes through Dc
5. **No Dynamic Memory:** Limited heap, avoid excessive allocations
6. **Palette-Based Graphics:** Many devices use color palettes

## Development Notes

- Always test on target devices or simulator
- Consider different screen sizes and shapes (round, semi-round, rectangular)
- Be mindful of color palette limitations
- Profile and optimize for memory and performance
- Use annotations for code organization
- Follow Garmin coding conventions


## Samples For Reference
The ./samples/ dir contains some example apps that may be useful for this project.

  2. MoxyField (samples/MoxyField/)
    - Advanced data field with complex graphics
    - Demonstrates responsive layout calculations
    - Shows custom drawing with dc.drawText(), dc.drawLine()
  3. FieldTimerEvents (samples/FieldTimerEvents/)
    - Data field with state management and lifecycle callbacks
    - Shows onTimerStart(), onTimerStop(), etc.

  Graphics Samples:

  4. Picker/ColorWheel (samples/Picker/)
    - Excellent for pixel-level drawing techniques
    - Uses dc.fillPolygon() and mathematical rendering
    - Grid-based generation pattern useful for QR matrix
  5. Analog (samples/Analog/)
    - Shows BufferedBitmap for performance optimization
    - Off-screen rendering techniques

  Key Graphics APIs for QR Code Rendering

  From the documentation and samples:
  - dc.fillRectangle(x, y, width, height) - Best for QR code modules (squares)
  - dc.drawLine(x1, y1, x2, y2) - For borders/grid
  - dc.setColor(foreground, background) - Color management
  - dc.getWidth() / dc.getHeight() - Responsive sizing
  - BufferedBitmap - For pre-rendered QR codes (performance)

# Compiling and running tests
Use the Makefile to build and test the app without the simulator.
You can't use make run because you won't be able to access the simulator.

# Python Tools
If you need to run a python script, always use uv to ensure the right environment. Use uv to make sure a venv exists and the required packages are installed.