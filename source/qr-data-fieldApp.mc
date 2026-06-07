import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;

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
        mView = new QRDataFieldView(getUserId());
        return [mView];
    }

    // Called when settings are changed in Garmin Connect Mobile
    function onSettingsChanged() as Void {
        if (mView != null) {
            mView.setQRData(getUserId());
        }
        WatchUi.requestUpdate();
    }

    hidden function getUserId() as String {
        var userId = Properties.getValue("userId") as String?;
        if (userId == null || userId.length() == 0) {
            return "NO ID SET";
        }
        return userId;
    }

}

function getApp() as qr_data_fieldApp {
    return Application.getApp() as qr_data_fieldApp;
}
