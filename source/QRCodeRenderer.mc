import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// QR Code renderer class
// Handles drawing QR code matrix to device context
// Uses BufferedBitmap caching to avoid expensive per-frame rendering
class QRCodeRenderer {

    // The QR code encoder
    private var mEncoder as QRCodeEncoder;

    // Module size in pixels
    private var mModuleSize as Number;

    // Offset for centering on screen
    private var mOffsetX as Number;
    private var mOffsetY as Number;

    // Colors
    private var mForegroundColor as ColorValue;
    private var mBackgroundColor as ColorValue;

    // Quiet zone (border) modules
    private const QUIET_ZONE = 4;

    // Cached bitmap for QR code (avoids O(n²) rendering each frame)
    private var mCachedBitmap as BufferedBitmap?;
    private var mCachedBitmapRef as BufferedBitmapReference?;
    private var mCacheValid as Boolean;
    private var mCachedWidth as Number;
    private var mCachedHeight as Number;
    private var mCachedModuleSize as Number;

    // Constructor
    // @param encoder The QR code encoder
    function initialize(encoder as QRCodeEncoder) {
        mEncoder = encoder;
        mModuleSize = 3; // Default module size
        mOffsetX = 0;
        mOffsetY = 0;
        mForegroundColor = Graphics.COLOR_BLACK;
        mBackgroundColor = Graphics.COLOR_WHITE;
        mCachedBitmap = null;
        mCachedBitmapRef = null;
        mCacheValid = false;
        mCachedWidth = 0;
        mCachedHeight = 0;
        mCachedModuleSize = 0;
    }

    // Set colors - invalidates cache if colors changed
    // @param foreground Foreground color (modules)
    // @param background Background color
    function setColors(foreground as ColorValue, background as ColorValue) as Void {
        if (mForegroundColor != foreground || mBackgroundColor != background) {
            mForegroundColor = foreground;
            mBackgroundColor = background;
            mCacheValid = false;
        }
    }

    // Invalidate the cache (call when QR data changes)
    function invalidateCache() as Void {
        mCacheValid = false;
        mCachedBitmap = null;
        mCachedBitmapRef = null;
    }

    // Calculate optimal module size and offsets for centering
    // Invalidates cache if dimensions changed
    // @param dc Device context
    function calculateLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Check if dimensions changed - invalidate cache if so
        if (width != mCachedWidth || height != mCachedHeight) {
            mCacheValid = false;
            mCachedWidth = width;
            mCachedHeight = height;
        }

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

    // Draw QR code to device context using cached bitmap
    // The expensive O(n²) rendering only happens when cache is invalid
    // @param dc Device context
    function draw(dc as Dc) as Void {
        // Draw background
        dc.setColor(mBackgroundColor, mBackgroundColor);
        dc.clear();

        // Check if we need to rebuild the cache
        if (!mCacheValid || mCachedBitmapRef == null) {
            System.println("QR Render: cache miss - rebuilding bitmap");
            renderToCache();
        } else {
            System.println("QR Render: cache hit - using cached bitmap");
        }

        // Draw cached bitmap to screen (single blit operation)
        if (mCachedBitmapRef != null) {
            dc.drawBitmap(mOffsetX, mOffsetY, mCachedBitmapRef);
        }
    }

    // Render QR code to cached BufferedBitmap
    // This is the expensive O(n²) operation - only called when cache is invalid
    private function renderToCache() as Void {
        System.println("QR Render: renderToCache() start");
        var matrix = mEncoder.getMatrix();
        var size = mEncoder.getSize();

        // Calculate bitmap size (QR code + quiet zone)
        var totalModules = size + (QUIET_ZONE * 2);
        var bitmapSize = totalModules * mModuleSize;
        System.println("QR Render: bitmap size = " + bitmapSize + "x" + bitmapSize);

        if (bitmapSize <= 0) {
            System.println("QR Render: invalid bitmap size, aborting");
            return;
        }

        // Create buffered bitmap with 2-color palette for efficiency
        System.println("QR Render: creating BufferedBitmap...");
        var options = {
            :width => bitmapSize,
            :height => bitmapSize,
            :palette => [mBackgroundColor, mForegroundColor] as Array<ColorValue>
        };

        mCachedBitmapRef = Graphics.createBufferedBitmap(options);
        if (mCachedBitmapRef == null) {
            System.println("QR Render: createBufferedBitmap returned null");
            return;
        }
        System.println("QR Render: BufferedBitmap created");

        // Get the actual BufferedBitmap from the reference
        mCachedBitmap = mCachedBitmapRef.get() as BufferedBitmap;
        if (mCachedBitmap == null) {
            System.println("QR Render: get() returned null");
            mCachedBitmapRef = null;
            return;
        }

        // Get the DC for the buffered bitmap
        var bufDc = mCachedBitmap.getDc();
        System.println("QR Render: got DC, drawing modules...");

        // Fill background
        bufDc.setColor(mBackgroundColor, mBackgroundColor);
        bufDc.clear();

        // Draw QR modules
        bufDc.setColor(mForegroundColor, mBackgroundColor);
        var qzOffset = QUIET_ZONE * mModuleSize;

        for (var row = 0; row < size; row++) {
            for (var col = 0; col < size; col++) {
                if (matrix[row][col]) {
                    var x = qzOffset + (col * mModuleSize);
                    var y = qzOffset + (row * mModuleSize);
                    bufDc.fillRectangle(x, y, mModuleSize, mModuleSize);
                }
            }
        }

        mCachedModuleSize = mModuleSize;
        mCacheValid = true;
        System.println("QR Render: renderToCache() complete");
    }

    // Draw QR code with optional label below
    // Uses cached bitmap - only redraws when layout/colors change
    // @param dc Device context
    // @param label Label text to display below QR code
    function drawWithLabel(dc as Dc, label as String) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var size = mEncoder.getSize();

        // Calculate available space for QR code (leave room for label)
        var labelHeight = dc.getFontHeight(Graphics.FONT_TINY);
        var availableHeight = height - labelHeight - 4; // 4px spacing

        // Calculate module size to fit in available space
        var totalModules = size + (QUIET_ZONE * 2);
        var maxModuleSizeX = width / totalModules;
        var maxModuleSizeY = availableHeight / totalModules;
        var newModuleSize = maxModuleSizeX < maxModuleSizeY ? maxModuleSizeX : maxModuleSizeY;

        if (newModuleSize < 1) {
            newModuleSize = 1;
        }

        // Check if module size changed - invalidate cache if so
        if (newModuleSize != mCachedModuleSize) {
            mCacheValid = false;
        }
        mModuleSize = newModuleSize;

        var qrSize = totalModules * mModuleSize;
        mOffsetX = (width - qrSize) / 2;
        mOffsetY = (availableHeight - qrSize) / 2;

        // Draw QR code (uses cached bitmap if valid)
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
