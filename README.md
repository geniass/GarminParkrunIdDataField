# QR Data Field

A Garmin Connect IQ data field that displays QR codes on your watch or cycling computer.

## Features

- Generate QR codes directly on your Garmin device
- Memory-optimized for wearable constraints
- Supports QR versions 1-3 (up to ~53 characters)
- Works as a data field during activities

## Supported Devices

Supports 100+ Garmin devices including:
- Fenix series (5, 6, 7, 8)
- Forerunner series (255, 265, 955, 965, etc.)
- Edge cycling computers (530, 540, 830, 840, 1040, 1050)
- Epix, Enduro, Venu, and more

## Building

### Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
- A developer key (generate one via the SDK)

### Build Commands

```bash
# Build for a specific device
make build PRODUCT=fr255

# Build and run in simulator
make run PRODUCT=fr255

# Run unit tests
make test PRODUCT=fr255

# Build release package for all devices
make publish
```

## Usage

1. Install the data field on your Garmin device
2. Add it to an activity profile as a data field
3. The QR code will display during your activity

## Project Structure

```
source/           # Main application source code
resources/        # UI resources (layouts, strings, drawables)
test/             # Unit tests
```

## License

See LICENSE file for details.
