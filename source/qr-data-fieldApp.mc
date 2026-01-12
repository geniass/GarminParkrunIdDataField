import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Data field app entry point
// Excluded when building watch app (use: -x watchapp)
(:exclude_when_watchapp)
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

(:exclude_when_watchapp)
function getApp() as qr_data_fieldApp {
    return Application.getApp() as qr_data_fieldApp;
}

// Standalone watch app entry point
// Excluded when building data field (use: -x datafield)
(:exclude_when_datafield)
class qr_watch_app extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new QRAppView(), new QRAppDelegate() ];
    }
}

(:exclude_when_datafield)
function getWatchApp() as qr_watch_app {
    return Application.getApp() as qr_watch_app;
}
