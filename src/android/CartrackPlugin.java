package com.outsystems.experts.cartrack;

import android.Manifest;
import android.content.pm.PackageManager;
import android.util.Log;

import com.cartrack.blesdk.ctg.BleListener;
import com.cartrack.blesdk.ctg.BleService;
import com.cartrack.blesdk.ctg.BleTerminal;
import com.cartrack.blesdk.enumerations.BleAction;
import com.cartrack.blesdk.enumerations.BleError;
import com.cartrack.blesdk.enumerations.BleSignalStrength;
import com.cartrack.blesdk.enumerations.GetVehicleStats;
import com.cartrack.blesdk.enumerations.GetVehicleStatus;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.PermissionHelper;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

/**
 * This class echoes a string called from JavaScript.
 */


public class CartrackPlugin extends CordovaPlugin implements BleListener {

    private BleTerminal BleTerminal;
    private HashMap<CallbackTypes, CallbackContext> CallbackContextList = new HashMap<>();
    private String TAG = "CartrackPlugin";
    public static final int START_REQ_CODE = 0;
    public static final int PERMISSION_DENIED_ERROR = 20;

    protected final static String[] permissions = {
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
        Manifest.permission.BLUETOOTH
    };

    enum CallbackTypes{
        SAVE_AUTH_KEY,
        GET_AUTH_KEY,
        SCAN_AND_CONNECT_TO_PERIPHERAL,
        DISCONNECT,
        REMOVE_AUTH_KEY,
        SEND_ACTION,
        ON_SIGNAL_STRENGTH,
        ON_ERROR,
        REQUEST_PERMISSIONS
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch (action) {
            case "configure":
                String terminalId = args.getString(0);
                this.configure(terminalId, callbackContext);
                return true;
            case "saveAuthKey":
                String authKey = args.getString(0);
                this.saveAuthKey(authKey, callbackContext);
                return true;
            case "getAuthKey":
                this.getAuthKey(callbackContext);
                return true;
            case "scanAndConnectToPeripheral":
                long timeoutSeconds = args.getLong(0);
                this.scanAndConnectToPeripheral(timeoutSeconds, callbackContext);
                return true;
            case "disconnect":
                this.disconnect(callbackContext);
                return true;
            case "removeAuthKey":
                this.removeAuthKey(callbackContext);
                return true;
            case "sendAction":
                String bleActionStr = args.getString(0);
                this.sendAction(bleActionStr, callbackContext);
                return true;
            case "onSignalStrength":
                this.onSignalStrength(callbackContext);
                return true;
            case "initErrorHandler":
                this.initErrorHandler(callbackContext);
                return true;
            case "requestPermissions":
                this.requestPermissions(callbackContext);
                return true;
        }
        return false;
    }

    private void configure(String terminalID, CallbackContext callbackContext) {
        BleService.Companion.configure(this.cordova.getContext());
        BleTerminal = BleService.Companion.getTerminal(terminalID);
        BleTerminal.setBleListener(this);
        callbackContext.success();
    }

    private void saveAuthKey(String authKey, CallbackContext callbackContext) {
        CallbackContextList.put(CallbackTypes.SAVE_AUTH_KEY, callbackContext);
        BleTerminal.saveAuthKey(authKey);
    }

    private void getAuthKey(CallbackContext callbackContext) {
        CallbackContextList.put(CallbackTypes.GET_AUTH_KEY, callbackContext);
        String authKey = BleTerminal.getAuthKey();
        if (callbackContext != null) {
            callbackContext.success(authKey);
        }
    }

    private void scanAndConnectToPeripheral(long timeoutSeconds, CallbackContext callbackContext){
        CallbackContextList.put(CallbackTypes.SCAN_AND_CONNECT_TO_PERIPHERAL, callbackContext);
        BleTerminal.scanAndConnectToPeripheral(timeoutSeconds);
    }

    private void disconnect(CallbackContext callbackContext){
        CallbackContextList.put(CallbackTypes.DISCONNECT, callbackContext);
        BleTerminal.disconnect();
    }

    private void removeAuthKey(CallbackContext callbackContext){
        CallbackContextList.put(CallbackTypes.REMOVE_AUTH_KEY, callbackContext);
        BleTerminal.removeAuthKey();
    }

    private void sendAction(String bleActionStr, CallbackContext callbackContext){
        try {
            CallbackContextList.put(CallbackTypes.SEND_ACTION, callbackContext);
            BleAction bleAction = BleAction.valueOf(bleActionStr);
            BleTerminal.sendAction(bleAction);
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
        }
    }

    private void onSignalStrength(CallbackContext callbackContext){
        Log.e(TAG, "onSignalStrength");
    }

    private void initErrorHandler(CallbackContext callbackContext){
        CallbackContextList.put(CallbackTypes.ON_ERROR, callbackContext);
        callbackContext.success();
    }

    private void requestPermissions(CallbackContext callbackContext){
        CallbackContextList.put(CallbackTypes.REQUEST_PERMISSIONS, callbackContext);
        if (hasPermisssion()) {
            callbackContext.success();
        } else {
            PermissionHelper.requestPermissions(this, START_REQ_CODE, permissions);
        }
    }

    @Override
    public void onError(BleError bleError) {

        CallbackContext callbackContext = CallbackContextList.get(CallbackTypes.ON_ERROR);

        JSONObject errorResponse = this.createJsonErrorResponse(bleError.getClass().getName(), bleError.getLocalizedDescription());

        PluginResult result = new PluginResult(PluginResult.Status.OK, errorResponse);
        result.setKeepCallback(true);

        Log.e(TAG, bleError.getLocalizedDescription());

        callbackContext.sendPluginResult(result);
    }

    private JSONObject createJsonErrorResponse(String code, String message) {
        Map<String, String> data = new HashMap<>();
        data.put("code", code);
        data.put("message", message);
        return new JSONObject(data);
    }

    @Override
    public void onRemoveAuthKeySuccess() {
        CallbackContext callbackContext = CallbackContextList.get(CallbackTypes.REMOVE_AUTH_KEY);
        if (callbackContext != null) {
            callbackContext.success();
            CallbackContextList.remove(CallbackTypes.REMOVE_AUTH_KEY);
        }
    }

    @Override
    public void onSaveAuthKeySuccess(BleTerminal bleTerminal, String s) {
        CallbackContext callbackContext = CallbackContextList.get(CallbackTypes.SAVE_AUTH_KEY);
        if (callbackContext != null) {
            callbackContext.success();
            CallbackContextList.remove(CallbackTypes.SAVE_AUTH_KEY);
        }
    }

    @Override
    public void onSignalStrength(BleSignalStrength bleSignalStrength) {
        CallbackContext callbackContext = CallbackContextList.get(CallbackTypes.ON_SIGNAL_STRENGTH);
        if (callbackContext != null) {
            callbackContext.success();
            CallbackContextList.remove(CallbackTypes.ON_SIGNAL_STRENGTH);
        }
    }

    @Override
    public void onTerminalCommandResult(BleAction bleAction) {
        Log.e(TAG, "onTerminalCommandResult");
    }

    @Override
    public void onTerminalConnected(BleTerminal bleTerminal) {
        CallbackContext callbackContext = CallbackContextList.get(CallbackTypes.SCAN_AND_CONNECT_TO_PERIPHERAL);
        if (callbackContext != null) {
            callbackContext.success();
            CallbackContextList.remove(CallbackTypes.SCAN_AND_CONNECT_TO_PERIPHERAL);
        }
    }

    @Override
    public void onTerminalDidGetVehicleStats(byte b, GetVehicleStats getVehicleStats) {
        Log.e(TAG, "onTerminalDidGetVehicleStats");
    }

    @Override
    public void onTerminalDidGetVehicleStatus(byte b, GetVehicleStatus getVehicleStatus) {
        Log.e(TAG, "onTerminalDidGetVehicleStatus");
    }

    @Override
    public void onTerminalDisconnected(BleTerminal bleTerminal) {
        CallbackContext callbackContext = CallbackContextList.get(CallbackTypes.DISCONNECT);
        if (callbackContext != null) {
            callbackContext.success();
            CallbackContextList.remove(CallbackTypes.DISCONNECT);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        for (int r : grantResults) {
            if (r == PackageManager.PERMISSION_DENIED) {
                Log.d(TAG, "Permission Denied!");
                PluginResult result = new PluginResult(PluginResult.Status.ERROR, PERMISSION_DENIED_ERROR);

                CallbackContext callbackContext = CallbackContextList.get(CallbackTypes.REQUEST_PERMISSIONS);

                if(callbackContext != null) {
                    callbackContext.sendPluginResult(result);
                }
                return;
            }
        }
    }

    public boolean hasPermisssion() {
        for(String p : permissions)
        {
            if(!PermissionHelper.hasPermission(this, p))
            {
                return false;
            }
        }
        return true;
    }
}
