import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

using QRCode;

module QRViewDelegate {

    // Renderer caches the bitmap; the expensive O(n²) draw only runs when
    // colors, size, or data have actually changed.
    function renderQRCode(dc as Dc, encoder as QRCode.Encoder, renderer as QRCode.Renderer,
                          label as String, fgColor as ColorValue, bgColor as ColorValue) as Boolean {
        renderer.setColors(fgColor, bgColor);
        renderer.drawWithLabel(dc, label);
        return true;
    }

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
