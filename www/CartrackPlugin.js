var exec = require('cordova/exec');

module.exports = {
    configure: function (terminalId, success, error) {
        exec(success, error, 'CartrackPlugin', 'configure', [terminalId]);
    },
    saveAuthKey: function (authKey, success, error) {
        exec(success, error, 'CartrackPlugin', 'saveAuthKey', [authKey]);
    },
    getAuthKey: function (success, error) {
        exec(success, error, 'CartrackPlugin', 'getAuthKey');
    }, 
    scanAndConnectToPeripheral: function (timeoutSeconds, success, error) {
        exec(success, error, 'CartrackPlugin', 'scanAndConnectToPeripheral', [timeoutSeconds]);
    },
    disconnect: function (success, error) {
        exec(success, error, 'CartrackPlugin', 'disconnect');
    },
    removeAuthKey: function (success, error) {
        exec(success, error, 'CartrackPlugin', 'removeAuthKey');
    },
    sendAction: function (actionId, success, error) {
        exec(success, error, 'CartrackPlugin', 'sendAction', [actionId]);
    },
    initErrorHandler: function (success, error) {
        exec(success, error, 'CartrackPlugin', 'initErrorHandler');
    },
    requestPermissions: function (success, error) {
        exec(success, error, 'CartrackPlugin', 'requestPermissions');
    }

};