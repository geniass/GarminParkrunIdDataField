import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// QR Code Standalone App View
// Displays QR code as a standalone watch application
// Uses chunked encoding to avoid watchdog timeout
class QRAppView extends WatchUi.View {

    // QR code components
    hidden var mEncoder as QRCodeEncoder?;
    hidden var mRenderer as QRCodeRenderer?;

    // Chunked encoder for async encoding
    hidden var mChunkedEncoder as QRCodeEncoderChunked?;

    // QR code data
    hidden var mQRData as String;
    hidden var mQRNeedsUpdate as Boolean;
    hidden var mIsEncoding as Boolean;

    function initialize() {
        View.initialize();
        mQRData = "A316388911";
        mQRNeedsUpdate = true;
        mEncoder = null;
        mRenderer = null;
        mChunkedEncoder = null;
        mIsEncoding = false;
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        mQRNeedsUpdate = true;
    }

    // Called when layout changes
    function onLayout(dc as Dc) as Void {
        // Only trigger re-encode if we already have an encoder
        // (layout changes shouldn't re-encode, just re-render)
        if (mRenderer != null) {
            mRenderer.invalidateCache();
        }
    }

    // Callback when chunked encoding completes
    function onEncodeComplete(encoder as QRCodeEncoder?) as Void {
        System.println("QRAppView: onEncodeComplete");
        mIsEncoding = false;

        if (encoder != null) {
            mEncoder = encoder;
            mRenderer = new QRCodeRenderer(mEncoder);
            mQRNeedsUpdate = false;
            System.println("QRAppView: encoder ready, requesting update");
        } else {
            System.println("QRAppView: encoding failed");
            mEncoder = null;
            mRenderer = null;
        }

        WatchUi.requestUpdate();
    }

    // Render the QR code
    function onUpdate(dc as Dc) as Void {
        // Standalone app uses white background with black QR
        var bgColor = Graphics.COLOR_WHITE;
        var fgColor = Graphics.COLOR_BLACK;

        // Start encoding if needed
        if (mQRNeedsUpdate && !mIsEncoding) {
            System.println("QRAppView: starting chunked encode");
            mIsEncoding = true;
            mQRNeedsUpdate = false;

            // Create chunked encoder if needed
            if (mChunkedEncoder == null) {
                mChunkedEncoder = new QRCodeEncoderChunked();
            }

            // Start async encoding
            mChunkedEncoder.startEncode(mQRData, 2, QRCodeEncoder.ERROR_LEVEL_L, method(:onEncodeComplete));

            // Show loading state
            dc.setColor(fgColor, bgColor);
            dc.clear();
            dc.drawText(
                dc.getWidth() / 2,
                dc.getHeight() / 2,
                Graphics.FONT_SMALL,
                "Encoding...",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }

        // Show loading state while encoding
        if (mIsEncoding) {
            dc.setColor(fgColor, bgColor);
            dc.clear();
            dc.drawText(
                dc.getWidth() / 2,
                dc.getHeight() / 2,
                Graphics.FONT_SMALL,
                "Encoding...",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }

        // Render QR code if we have one
        if (mEncoder != null && mRenderer != null) {
            if (!QRViewDelegate.renderQRCode(dc, mEncoder, mRenderer, mQRData, fgColor, bgColor)) {
                QRViewDelegate.drawError(dc, "QR Error", fgColor, bgColor);
            }
        } else {
            QRViewDelegate.drawError(dc, "No QR Data", fgColor, bgColor);
        }
    }

    // Allow external setting of QR data
    function setQRData(data as String) as Void {
        if (!mQRData.equals(data)) {
            mQRData = data;
            mQRNeedsUpdate = true;

            // Stop any existing encoding
            if (mChunkedEncoder != null) {
                mChunkedEncoder.stopEncode();
            }
            mIsEncoding = false;

            WatchUi.requestUpdate();
        }
    }
}

// Input delegate for standalone app
// Handles button presses and back navigation
class QRAppDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Handle back button - exit app
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
