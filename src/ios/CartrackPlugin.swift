//
//  CartrackPlugin.swift
//  CartrackPlugin
//
//  Created by Andre Grillo on 06/10/2022.
//
import CoreBluetooth
import CartrackBleLockSDK
import Foundation

@objc(CartrackPlugin)
class CartrackPlugin: CDVPlugin {
    var pluginResult = CDVPluginResult()
    var pluginCommand = CDVInvokedUrlCommand()
    var bleTerminal: BleTerminal?
    var callbackCommandDict:[CallbackTypes:CDVInvokedUrlCommand] = [:]
    
    @objc (configure:)
    func configure(_ command: CDVInvokedUrlCommand) {
        
        if let terminalId = command.arguments[0] as? String {
            bleTerminal = BleService.getTerminal(terminalID: terminalId)
            bleTerminal?.delegate = self
            
            UserDefaults.standard.set(terminalId, forKey: "terminal_id")
            
            print("Set Terminal ID successful")
        }
    }
    
    @objc (saveAuthKey:)
    func saveAuthKey(_ command: CDVInvokedUrlCommand) {
        pluginCommand = command
        if let authKey = command.arguments[0] as? String {
            bleTerminal?.saveAuthKey(authKey: authKey)
            print("AuthKey saved")
        }
    }
    
    @objc (getAuthKey:)
    func getAuthKey(_ command: CDVInvokedUrlCommand) {
        pluginCommand = command
        if let authKey = bleTerminal?.authKey {
            print("AuthKey fetched: \(authKey)")
            sendPluginResult(status: CDVCommandStatus_OK, message: authKey)
        }
    }
    
    @objc (scanAndConnectToPeripheral:)
    func scanAndConnectToPeripheral(_ command: CDVInvokedUrlCommand) {
        pluginCommand = command
//        if let timeoutSeconds = command.arguments[0] as? Int {
            print("Connecting...")
            bleTerminal?.connect()
//        }
    }
    
    @objc (disconnect)
    func disconnect() {
        print("Disconnecting...")
        bleTerminal?.disconnect()
    }
    
    @objc (removeAuthKey)
    func removeAuthKey() {
        bleTerminal?.removeAuthKey()
        if bleTerminal?.hasKey ?? false {
            print("Remove Key failed")
        } else {
            print("Remove Key Successful")
        }
    }
    
    @objc (sendAction:)
    func sendAction(_ command: CDVInvokedUrlCommand) {
        if let bleActionString = command.arguments[0] as? String {
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
    }
    
    @objc (initErrorHandler)
    func initErrorHandler() {
        //???
    }
    
    @objc (requestPermissions:)
    func requestPermissions(_ command: CDVInvokedUrlCommand) {
        print("Permission request")
        //???
    }
    
    @objc (getLockState:)
    func getLockState(_ command: CDVInvokedUrlCommand) {
        pluginCommand = command
        let lockState: LockState = bleTerminal?.lockState ?? .unknown
        switch lockState {
        case .locked:
            sendPluginResult(status: CDVCommandStatus_OK, message: "locked")
        case .unlocked:
            sendPluginResult(status: CDVCommandStatus_OK, message: "unlocked")
        default:
            sendPluginResult(status: CDVCommandStatus_OK, message: "unknown")
        }
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
            sendPluginResult(status: CDVCommandStatus_OK, message: "OK")
        }
    }
    
    func bleTerminalDidConnect(terminal: BleTerminal, error: BleError?) {
        if let error = error {
          print("Failed to connect, message: \(error.errorCode) \(error.localizedDescription)")
        } else {
            sendPluginResult(status: CDVCommandStatus_OK, message: "Connected")
        }
    }
    
    func bleTerminalDidAction(terminal: BleTerminal, action: BleAction, error: BleError?) {
        if let error = error {
          print("Action Failed, message: [\(error.actionCode)] [\(action)] Failed\nReason: [\(error.errorCode)]\(error.localizedDescription)")
        } else {
            switch action {
            case .lockState:
                print("Action, Vehicle's door is \(terminal.lockState)")
                sendPluginResult(status: CDVCommandStatus_OK, message: "\(terminal.lockState)")
            case .lock:
                print("Action, Lock Action Success\nLock state: [\(terminal.lockState)]")
                sendPluginResult(status: CDVCommandStatus_OK, message: "\(terminal.lockState)")
            case .unlock:
                print("Action, Unlock Action Success\nLock state: [\(terminal.lockState)]")
                sendPluginResult(status: CDVCommandStatus_OK, message: "\(terminal.lockState)")
            case .unlockNoKeyFob:
                print("Action, Unlock with No Key Fob Action Success\nLock state: [\(terminal.lockState)]")
                sendPluginResult(status: CDVCommandStatus_OK, message: "\(terminal.lockState)")
            case .horn:
                print("Action, Horn Action Success")
                sendPluginResult(status: CDVCommandStatus_OK, message: "Horn ok")
            case .headlight:
                print("Action,Headlight Action Success")
                sendPluginResult(status: CDVCommandStatus_OK, message: "headlight ok")
            case .ignitionState:
                print("Action, Vehicle's ignition state is \(terminal.ignitionState)")
                sendPluginResult(status: CDVCommandStatus_OK, message: "\(terminal.ignitionState)")
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
