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

    function initialize(qrData as String) {
        DataField.initialize();

        mQRData = qrData;
        mQRNeedsUpdate = true;
        mEncoder = null;
        mRenderer = null;
    }

    // Called when layout changes
    function onLayout(dc as Dc) as Void {
        // Only invalidate render cache, don't re-encode
        if (mRenderer != null) {
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

        // Encode QR if needed (synchronous - data fields can't use timers)
        if (mQRNeedsUpdate || mEncoder == null) {
            // Have to use Version 1 (21x21) due to data field processing time constraints
            mEncoder = QRViewDelegate.createEncoder(mQRData, 1, QRCode.Encoder.ERROR_LEVEL_L);
            if (mEncoder != null) {
                mRenderer = new QRCode.Renderer(mEncoder);
                mQRNeedsUpdate = false;
            } else {
                QRViewDelegate.drawError(dc, "QR Error", fgColor, bgColor);
                return;
            }
        }

        // Render
        if (!QRViewDelegate.renderQRCode(dc, mEncoder, mRenderer, mQRData, fgColor, bgColor)) {
            QRViewDelegate.drawError(dc, "QR Error", fgColor, bgColor);
        }
    }

    // Allow external setting of QR data
    function setQRData(data as String) as Void {
        if (!mQRData.equals(data)) {
            mQRData = data;
            mQRNeedsUpdate = true;
        }
    }
}
