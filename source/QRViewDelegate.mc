import Toybox.Graphics;
import Toybox.Lang;

using QRCode;

// Shared QR code display logic used by both data field and standalone app views
// This module contains the common rendering functionality
module QRViewDelegate {

    // Render the QR code with optional label
    // Uses cached bitmap rendering - expensive O(n²) drawing only happens
    // when colors, size, or data changes
    // @param dc Device context
    // @param encoder QR code encoder (already encoded)
    // @param renderer QR code renderer
    // @param data The data string to display as label
    // @param fgColor Foreground color
    // @param bgColor Background color
    function renderQRCode(dc as Dc, encoder as QRCode.Encoder?, renderer as QRCode.Renderer?,
                          data as String, fgColor as ColorValue, bgColor as ColorValue) as Boolean {
        if (encoder == null || renderer == null) {
            return false;
        }

        // Set colors (invalidates cache if changed)
        renderer.setColors(fgColor, bgColor);

        // Draw QR code with label (handles caching internally)
        renderer.drawWithLabel(dc, data);
        return true;
    }

    // Create and encode a new QR code
    // @param data The data to encode
    // @param version QR code version (1-3)
    // @param errorLevel Error correction level
    // @return The encoder if successful, null otherwise
    function createEncoder(data as String, version as Number, errorLevel as Number) as QRCode.Encoder? {
        var encoder = new QRCode.Encoder(version, errorLevel);
        if (encoder.encode(data)) {
            return encoder;
        }
        return null;
    }

    // Draw an error message centered on screen
    // @param dc Device context
    // @param message Error message to display
    // @param fgColor Foreground color
    // @param bgColor Background color
    function drawError(dc as Dc, message as String, fgColor as ColorValue, bgColor as ColorValue) as Void {
        dc.setColor(fgColor, bgColor);
        dc.clear();
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_SMALL,
            message,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
