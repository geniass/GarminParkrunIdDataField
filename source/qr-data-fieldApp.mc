import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;

// Data field app entry point
class qr_data_fieldApp extends Application.AppBase {
    hidden var mView as QRDataFieldView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        // TODO: show a different view if no user ID is set
        var userId = Properties.getValue("userId") as String?;
        if (userId == null || userId.length() == 0) {
            userId = "NO ID SET";
        }
        mView = new QRDataFieldView(userId);
        return [mView];
    }

    // Called when settings are changed in Garmin Connect Mobile
    function onSettingsChanged() as Void {
        var userId = Properties.getValue("userId") as String?;
        if (userId == null || userId.length() == 0) {
            userId = "NO ID SET";
        }
        if (mView != null) {
            mView.setQRData(userId);
        }
        WatchUi.requestUpdate();
    }
}

function getApp() as qr_data_fieldApp {
    return Application.getApp() as qr_data_fieldApp;
}
