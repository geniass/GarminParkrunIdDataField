import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Data field app entry point
class qr_data_fieldApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new QRDataFieldView("A3163889") ];
    }
}

function getApp() as qr_data_fieldApp {
    return Application.getApp() as qr_data_fieldApp;
}
