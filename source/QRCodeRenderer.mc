import Toybox.Graphics;
import Toybox.Lang;

// QR Code renderer class
// Handles drawing QR code matrix to device context
class QRCodeRenderer {

    // The QR code encoder
    private var mEncoder as QRCodeEncoder;

    // Module size in pixels
    private var mModuleSize as Number;

    // Offset for centering
    private var mOffsetX as Number;
    private var mOffsetY as Number;

    // Colors
    private var mForegroundColor as ColorValue;
    private var mBackgroundColor as ColorValue;

    // Quiet zone (border) modules
    private const QUIET_ZONE = 4;

    // Constructor
    // @param encoder The QR code encoder
    function initialize(encoder as QRCodeEncoder) {
        mEncoder = encoder;
        mModuleSize = 3; // Default module size
        mOffsetX = 0;
        mOffsetY = 0;
        mForegroundColor = Graphics.COLOR_BLACK;
        mBackgroundColor = Graphics.COLOR_WHITE;
    }

    // Set colors
    // @param foreground Foreground color (modules)
    // @param background Background color
    function setColors(foreground as ColorValue, background as ColorValue) as Void {
        mForegroundColor = foreground;
        mBackgroundColor = background;
    }

    // Calculate optimal module size and offsets for centering
    // @param dc Device context
    function calculateLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var size = mEncoder.getSize();

        // Total size including quiet zone
        var totalModules = size + (QUIET_ZONE * 2);

        // Calculate module size to fit in available space
        var maxModuleSizeX = width / totalModules;
        var maxModuleSizeY = height / totalModules;
        mModuleSize = maxModuleSizeX < maxModuleSizeY ? maxModuleSizeX : maxModuleSizeY;

        // Ensure minimum module size of 1
        if (mModuleSize < 1) {
            mModuleSize = 1;
        }

        // Calculate total QR code size
        var qrWidth = totalModules * mModuleSize;
        var qrHeight = totalModules * mModuleSize;

        // Center the QR code
        mOffsetX = (width - qrWidth) / 2;
        mOffsetY = (height - qrHeight) / 2;
    }

    // Draw QR code to device context
    // @param dc Device context
    function draw(dc as Dc) as Void {
        var matrix = mEncoder.getMatrix();
        var size = mEncoder.getSize();

        // Draw background
        dc.setColor(mBackgroundColor, mBackgroundColor);
        dc.clear();

        // Draw quiet zone and QR code
        dc.setColor(mForegroundColor, mBackgroundColor);

        // Add quiet zone offset
        var qzOffset = QUIET_ZONE * mModuleSize;

        // Draw each module
        for (var row = 0; row < size; row++) {
            for (var col = 0; col < size; col++) {
                if (matrix[row][col]) {
                    var x = mOffsetX + qzOffset + (col * mModuleSize);
                    var y = mOffsetY + qzOffset + (row * mModuleSize);
                    dc.fillRectangle(x, y, mModuleSize, mModuleSize);
                }
            }
        }
    }

    // Draw QR code with optional label below
    // @param dc Device context
    // @param label Label text to display below QR code
    function drawWithLabel(dc as Dc, label as String) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var size = mEncoder.getSize();

        // Calculate available space for QR code (leave room for label)
        var labelHeight = dc.getFontHeight(Graphics.FONT_TINY);
        var availableHeight = height - labelHeight - 4; // 4px spacing

        // Temporarily adjust calculation to fit in available space
        var totalModules = size + (QUIET_ZONE * 2);
        var maxModuleSizeX = width / totalModules;
        var maxModuleSizeY = availableHeight / totalModules;
        mModuleSize = maxModuleSizeX < maxModuleSizeY ? maxModuleSizeX : maxModuleSizeY;

        if (mModuleSize < 1) {
            mModuleSize = 1;
        }

        var qrSize = totalModules * mModuleSize;
        mOffsetX = (width - qrSize) / 2;
        mOffsetY = (availableHeight - qrSize) / 2;

        // Draw QR code
        draw(dc);

        // Draw label
        dc.setColor(mForegroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            availableHeight + 2,
            Graphics.FONT_TINY,
            label,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // Get the calculated module size
    function getModuleSize() as Number {
        return mModuleSize;
    }
}
