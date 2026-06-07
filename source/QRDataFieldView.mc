import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

using QRCode;

// Displays QR code as a data field during activities
// Data fields cannot use Timers, so QR encoding runs synchronously in onUpdate.
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
    // Version 1 QR is 21 modules + 4-module quiet zone = 25, and needs ~4px per
    // module to scan reliably. The threshold is set slightly higher for margin.
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
        // Theme colors for error/status text only — these follow the data
        // field's current theme so messages look natural.
        var dfBg = getBackgroundColor();
        var dfFg = (dfBg == Graphics.COLOR_BLACK) ?
            Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        // Show message if field is too small for scannable QR code
        if (mTooSmall) {
            QRViewDelegate.drawError(dc, "Use single\nfield layout", dfFg, dfBg);
            return;
        }

        if (mEncoder == null || mRenderer == null) {
            QRViewDelegate.drawError(dc, "QR Error", dfFg, dfBg);
            return;
        }

        if (mQRNeedsUpdate) {
            mEncoder.encode(mQRData);
            mQRNeedsUpdate = false;
        }

        // Scanners require dark-on-light. On AMOLED activity screens the data
        // field background is black, so matching the theme would produce an
        // unscannable negative — force black/white for the QR itself.
        QRViewDelegate.renderQRCode(dc, mEncoder, mRenderer, mQRData,
            Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    }

    function setQRData(data as String) as Void {
        if (!mQRData.equals(data)) {
            mQRData = data;
            mQRNeedsUpdate = true;
            if (mRenderer != null) {
                mRenderer.invalidateCache();
            }
        }
    }
}
