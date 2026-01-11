import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;

class qr_data_fieldView extends WatchUi.DataField {

    // QR code components
    hidden var mEncoder as QRCodeEncoder?;
    hidden var mRenderer as QRCodeRenderer?;

    // Workout data
    hidden var mHeartRate as Number;
    hidden var mDistance as Float;
    hidden var mDuration as Number;
    hidden var mPace as Float;

    // QR code data
    hidden var mQRData as String;
    hidden var mQRNeedsUpdate as Boolean;

    function initialize() {
        DataField.initialize();
        mHeartRate = 0;
        mDistance = 0.0f;
        mDuration = 0;
        mPace = 0.0f;
        mQRData = "HELLO";
        mQRNeedsUpdate = true;
        mEncoder = null;
        mRenderer = null;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        // For QR code display, we'll use custom drawing instead of layouts
        // Don't set any layout - we'll draw directly in onUpdate
        mQRNeedsUpdate = true;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // Collect workout data
        if (info has :currentHeartRate && info.currentHeartRate != null) {
            mHeartRate = info.currentHeartRate as Number;
        }

        if (info has :elapsedDistance && info.elapsedDistance != null) {
            mDistance = (info.elapsedDistance as Float) / 1000.0f; // Convert to km
        }

        if (info has :timerTime && info.timerTime != null) {
            mDuration = (info.timerTime as Number) / 1000; // Convert to seconds
        }

        if (info has :currentSpeed && info.currentSpeed != null) {
            var speed = info.currentSpeed as Float;
            if (speed > 0) {
                mPace = 1000.0f / (speed * 60.0f); // min/km
            }
        }

        // Build QR data string with parkrun URL
        // Note: Alphanumeric mode requires uppercase, but URLs work fine in uppercase
        // The toUpper() in encode() will convert it automatically
        mQRData = "A3163889";

        mQRNeedsUpdate = true;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set background color
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_BLACK) ?
            Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(fgColor, bgColor);
        dc.clear();

        // Generate QR code if needed
        if (mQRNeedsUpdate || mEncoder == null) {
            mEncoder = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);

            if (mEncoder.encode(mQRData)) {
                mRenderer = new QRCodeRenderer(mEncoder);
                mRenderer.setColors(fgColor, bgColor);
                mRenderer.calculateLayout(dc);
                mQRNeedsUpdate = false;
            } else {
                // If encoding fails, display error
                dc.drawText(
                    dc.getWidth() / 2,
                    dc.getHeight() / 2,
                    Graphics.FONT_SMALL,
                    "QR Error",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
                return;
            }
        }

        // Draw QR code with label showing the data
        if (mRenderer != null) {
            mRenderer.drawWithLabel(dc, mQRData);
        }
    }

}
