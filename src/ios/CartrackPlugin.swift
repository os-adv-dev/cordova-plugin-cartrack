//
//  CartrackPlugin.swift
//  CartrackPlugin
//
//  Created by Andre Grillo on 06/10/2022.
//
import CoreBluetooth
import CartrackBleLockSDK
import Foundation

class CartrackPlugin {
    
    var bleTerminal: BleTerminal?
    var callbackCommandDict:[CallbackTypes:CDVInvokedUrlCommand] = []
    
    
    @objc (configure:)
    func configure(_ command: CDVInvokedUrlCommand, terminalId: String) {
        bleTerminal = BleService.getTerminal(terminalID: terminalId)
        bleTerminal?.delegate = self
        
        UserDefaults.standard.set(terminalId, forKey: "terminal_id")
        
        print("Set Terminal ID successful")
    }
    
    @objc (saveAuthKey:)
    func saveAuthKey(authKey: String) {
        bleTerminal?.saveAuthKey(authKey: authKey)
        print("AuthKey saved")
    }
    
    @objc (getAuthKey:)
    func getAuthKey() {
        print(bleTerminal?.authKey)
    }
    
    @objc (scanAndConnectToPeripheral:)
    func scanAndConnectToPeripheral(timeoutSeconds: Int) {
        print("Connecting...")
        bleTerminal?.connect()
    }
    
    @objc (disconnect:)
    func disconnect() {
        print("Disconnecting...")
        bleTerminal?.disconnect()
    }
    
    @objc (removeAuthKey:)
    func removeAuthKey() {
        bleTerminal?.removeAuthKey()
        if bleTerminal?.hasKey ?? false {
            print("Remove Key failed")
        } else {
            print("Remove Key Successful")
        }
    }
    
    @objc (sendAction:)
    func sendAction(bleActionString: String) {
        switch bleActionString {
        case "LOCK":
            bleTerminal?.sendAction(.lock)
        case "UNLOCK":
            bleTerminal?.sendAction(.unlock)
        case "HORN":
            bleTerminal?.sendAction(.horn)
        case "GET_LOCK_STATE":
            bleTerminal?.sendAction(.lockState)
        case "HEADLIGHT":
            bleTerminal?.sendAction(.headlight)
        case "UNLOCK_NOKEYFOB":
            bleTerminal?.sendAction(.unlockNoKeyFob)
        //case "VEHICLE_GET_CONFIG":      //ANDROID ONLY?
        case "IGNITION_STATE":
            bleTerminal?.sendAction(.ignitionState)
        case "VEHICLE_GET_STATUS":
            bleTerminal?.getVehicleStats()
        default:
            print("Action not available on iOS")
        }
    }
    
    @objc (initErrorHandler:)
    func initErrorHandler() {
        //???
    }
    
    @objc (requestPermissions:)
    func requestPermissions() {
        //???
    }
    
    @objc (getLockState:)
    func getLockState() {
        bleTerminal?.sendAction(.lockState)
    }
    
    func sendPluginResult(status: CDVCommandStatus, message: String) {
        pluginResult = CDVPluginResult(status: status, messageAs: message)
        self.commandDelegate!.send(pluginResult, callbackId: pluginCommand.callbackId)
    }
}

extension CartrackPlugin: BleTerminalDelegate {

    func bleTerminalDidSavedKey(terminal: BleTerminal, error: BleError?) {
        if let error = error {
          print("Save Key Failed, message: \(error.errorCode) \(error.localizedDescription)")
        } else {
          print("Save Key Successful, Successful save authentication key!")
        }
    }
    
    func bleTerminalDidConnect(terminal: BleTerminal, error: BleError?) {
        if let error = error {
          print("Failed to connect, message: \(error.errorCode) \(error.localizedDescription)")
        }
    }
    
    func bleTerminalDidAction(terminal: BleTerminal, action: BleAction, error: BleError?) {
        if let error = error {
          print("Action Failed, message: [\(error.actionCode)] [\(action)] Failed\nReason: [\(error.errorCode)]\(error.localizedDescription)")
        } else {
            switch action {
            case .lockState:
                print("Action, Vehicle's door is \(terminal.lockState)")
            case .lock:
                print("Action, Lock Action Success\nLock state: [\(terminal.lockState)]")
            case .unlock:
                print("Action, Unlock Action Success\nLock state: [\(terminal.lockState)]")
            case .unlockNoKeyFob:
                print("Action, Unlock with No Key Fob Action Success\nLock state: [\(terminal.lockState)]")
            case .horn:
                print("Action, Horn Action Success")
            case .headlight:
                showMessage("Action,Headlight Action Success")
            case .ignitionState:
              showMessage("Action, Vehicle's ignition state is \(terminal.ignitionState)")
            @unknown default:
                break
            }
        }
    }

    func bleTerminalDidGetVehicleStats(terminal: BleTerminal, vehicleStats: VehicleStats?, error: BleError?) {
        if let error = error {
          print("Action Failed, [\(error.actionCode)] get vehicle stats Failed\nReason: [\(error.errorCode)] \(error.localizedDescription)")
        } else {
            print("vehicleStats: \(vehicleStats)")
        }
    }
    
    func bleTerminalDisconnected(terminal: BleTerminal) {
        print("Disconnected")

    }
    
    func bleTerminalSignalUpdate(rssi: Int, strength: BleSignalStrength) {
        print("RSSI: \(rssi) dBm (\(strength))")
    }
}

enum CallbackTypes: String, CaseIterable {
    case saveAuthKey = "SAVE_AUTH_KEY"
    case scanAndConnect = "SCAN_AND_CONNECT_TO_PERIPHERAL"
    case disconnect = "DISCONNECT"
    case removeAuthKey = "REMOVE_AUTH_KEY"
    case sendAction = "SEND_ACTION"
    case onError = "ON_ERROR"
    case requestPermissions = "REQUEST_PERMISSIONS"
        
    static func withString(_ label: String) -> CallbackTypes? {
        return self.allCases.first{ "\($0)" == label }
    }
}
