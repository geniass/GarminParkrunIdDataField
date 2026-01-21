import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

using QRCode;

// QR Code Data Field View
// Displays QR code as a data field during activities
// Note: Data fields cannot use Timers, so this uses synchronous encoding
class QRDataFieldView extends WatchUi.DataField {

    // QR code components
    hidden var mEncoder as QRCode.Encoder?;
    hidden var mRenderer as QRCode.Renderer?;

    // QR code data
    hidden var mQRData as String;
    hidden var mQRNeedsUpdate as Boolean;

    // Track layout dimensions to avoid redundant reinitializations
    hidden var mLastWidth as Number = 0;
    hidden var mLastHeight as Number = 0;

    // Minimum size for a scannable QR code (pixels)
    // Version 1 QR = 21 modules + 4 quiet zone = 25, need ~4px per module minimum
    // Min size here is slightly bigger to allow some margin
    // TODO: handle layouts where width != height
    hidden const MIN_QR_SIZE = 150;
    hidden var mTooSmall as Boolean = false;

    function initialize(qrData as String) {
        DataField.initialize();

        mQRData = qrData;
        mQRNeedsUpdate = true;
        mEncoder = null;
        mRenderer = null;
    }

    // Called when layout changes
    function onLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Only process if dimensions actually changed
        if (width == mLastWidth && height == mLastHeight) {
            return;
        }

        System.println("QRDataFieldView: onLayout " + width + "x" + height);
        mLastWidth = width;
        mLastHeight = height;

        // Check if field is too small for a scannable QR code
        var minDimension = (width < height) ? width : height;
        mTooSmall = (minDimension < MIN_QR_SIZE);
        if (mTooSmall) {
            System.println("QRDataFieldView: Field too small (" + minDimension + "px < " + MIN_QR_SIZE + "px)");
            return;
        }

        // Only create encoder/renderer once
        if (mEncoder == null) {
            mEncoder = new QRCode.Encoder(1, QRCode.Encoder.ERROR_LEVEL_L);
            mRenderer = new QRCode.Renderer(mEncoder);
            mRenderer.calculateLayout(dc);
        } else {
            // Dimensions changed - invalidate render cache
            mRenderer.invalidateCache();
        }
    }

    // Collect workout data from activity
    function compute(info as Activity.Info) as Void {
    }

    // Render the QR code
    function onUpdate(dc as Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_BLACK) ?
            Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        // Show message if field is too small for scannable QR code
        if (mTooSmall) {
            QRViewDelegate.drawError(dc, "Use single\nfield layout", fgColor, bgColor);
            return;
        }

        // Encode QR if needed (synchronous - data fields can't use timers)
        if (mQRNeedsUpdate || mEncoder == null) {
            // Have to use Version 1 (21x21) due to data field processing time constraints
            // mEncoder = QRViewDelegate.createEncoder(mQRData, 1, QRCode.Encoder.ERROR_LEVEL_L);
            mEncoder.encode(mQRData);
            if (mEncoder != null) {
                // mRenderer = new QRCode.Renderer(mEncoder);
                mQRNeedsUpdate = false;
            } else {
                QRViewDelegate.drawError(dc, "QR Error", fgColor, bgColor);
                return;
            }
        }

        if (!QRViewDelegate.renderQRCode(dc, mEncoder, mRenderer, mQRData, fgColor, bgColor)) {
            QRViewDelegate.drawError(dc, "QR Error", fgColor, bgColor);
        }
    }

    // Allow external setting of QR data
    function setQRData(data as String) as Void {
        if (!mQRData.equals(data)) {
            mQRData = data;
            mQRNeedsUpdate = true;
            mRenderer.invalidateCache();
        }
    }
}
