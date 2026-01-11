import Toybox.Lang;
import Toybox.Test;
import Toybox.Graphics;

(:test)
class QRCodeRendererTest {

    // Test renderer initialization
    (:test)
    function testRendererInitialization(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        encoder.encode("TEST");

        var renderer = new QRCodeRenderer(encoder);

        logger.debug("Renderer initialized successfully");
        Test.assert(renderer != null);

        return true;
    }

    // Test color setting
    (:test)
    function testSetColors(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        encoder.encode("TEST");

        var renderer = new QRCodeRenderer(encoder);

        // Should not throw error
        renderer.setColors(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        renderer.setColors(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        renderer.setColors(Graphics.COLOR_RED, Graphics.COLOR_BLUE);

        logger.debug("Color setting works correctly");

        return true;
    }

    // Test renderer with different QR versions
    (:test)
    function testDifferentVersionRenderers(logger as Logger) as Boolean {
        var encoder1 = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        encoder1.encode("TEST");
        var renderer1 = new QRCodeRenderer(encoder1);

        var encoder2 = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        encoder2.encode("TEST");
        var renderer2 = new QRCodeRenderer(encoder2);

        var encoder3 = new QRCodeEncoder(3, QRCodeEncoder.ERROR_LEVEL_L);
        encoder3.encode("TEST");
        var renderer3 = new QRCodeRenderer(encoder3);

        logger.debug("All renderers created successfully");
        Test.assert(renderer1 != null);
        Test.assert(renderer2 != null);
        Test.assert(renderer3 != null);

        return true;
    }

    // Test renderer with workout data format
    (:test)
    function testRendererWithWorkoutData(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(2, QRCodeEncoder.ERROR_LEVEL_L);
        var result = encoder.encode("HR:150 D:5.67 T:1800");

        logger.debug("Workout data encode result: " + result);
        Test.assert(result);

        var renderer = new QRCodeRenderer(encoder);
        Test.assert(renderer != null);

        logger.debug("Renderer created with workout data");

        return true;
    }

    // Test multiple color changes
    (:test)
    function testMultipleColorChanges(logger as Logger) as Boolean {
        var encoder = new QRCodeEncoder(1, QRCodeEncoder.ERROR_LEVEL_L);
        encoder.encode("TEST");

        var renderer = new QRCodeRenderer(encoder);

        // Should handle multiple color changes without errors
        for (var i = 0; i < 5; i++) {
            renderer.setColors(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
            renderer.setColors(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        }

        logger.debug("Multiple color changes handled correctly");

        return true;
    }
}
