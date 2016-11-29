//
//  PositionModel.swift
//  SchoolBus
//
//  Created by Paul Freeman on 14/11/2016.
//  Copyright © 2016 Paul Freeman. All rights reserved.
//

import Foundation
import AblyRealtime

public protocol PositionModelDelegate {
    func positionModel(_ positionModel: PositionModel, connectionStateChanged:ARTConnectionStateChange)
    func positionModelDidFinishSendingMessage(_ positionModel: PositionModel)
    func positionModel(_ positionModel: PositionModel, didReceiveMessage message: ARTMessage)
    func positionModel(_ positionModel: PositionModel, didReceiveError error: ARTErrorInfo)
}

open class PositionModel {
    fileprivate var ablyClientOptions: ARTClientOptions
    fileprivate var ablyRealtime: ARTRealtime?
    fileprivate var channel: ARTRealtimeChannel?
    
    open var clientId: String
    open var delegate: PositionModelDelegate?
    
    public init(clientId: String) {
        self.clientId = clientId
        
        ablyClientOptions = ARTClientOptions()
        ablyClientOptions.key = "QGOsVA.UnM4VQ:YuOO9DIWTgs2BcPZ"
        ablyClientOptions.clientId = clientId

        
        // Register without parameter
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActiveEventReceived), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForegroundEventReceived), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminateEventReceived), name: .UIApplicationWillTerminate ,object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveEventReceived), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackgroundEventReceived), name: .UIApplicationDidEnterBackground , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidFinishLaunchingEventReceived), name: .UIApplicationDidFinishLaunching, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationBackgroundRefreshStatusDidChange), name: .UIApplicationBackgroundRefreshStatusDidChange, object: nil)
        
    }
    
    open func connect() {

        self.ablyRealtime = ARTRealtime(key: "QGOsVA.UnM4VQ:YuOO9DIWTgs2BcPZ")
        let realtime = self.ablyRealtime!
        
        realtime.connection.on { stateChange in
            if let stateChange = stateChange {
                self.delegate?.positionModel(self, connectionStateChanged: stateChange)
                
                switch stateChange.current {
                case .connected:
                    
                    logXC.debug("state change to connected")
                    self.attemptReconnect(100)
                case .disconnected:
                    logXC.debug("state change to disconnected")
                    self.attemptReconnect(5000)
                case .suspended:
                    logXC.debug("state change to suspended")
                    self.attemptReconnect(5000)
                default:
                    break
                }
            }
        }
        
        channel = realtime.channels.get("Position")
        self.joinChannel()

    }
    
    // Leaves channel by disconnecting from Ably
    open func disconnect() {
        self.ablyRealtime?.connection.close()
    };
    
    open func publishMessage(_ message: String) {
        self.channel?.publish(self.clientId, data: message, clientId: self.clientId) { error in
            guard error == nil else {
                self.signalError(error!)
                return
            }
            
            self.delegate?.positionModelDidFinishSendingMessage(self)
        }
    }

    
    fileprivate func attemptReconnect(_ delay: Double) {
        self.delay(delay) {
            self.ablyRealtime?.connect()
            self.joinChannel()
        }
    }
    
    fileprivate func joinChannel() {
        
        guard let channel = self.channel else { return }
        
        channel.attach()
        channel.subscribe { self.delegate?.positionModel(self, didReceiveMessage: $0) }
        channel.once(ARTChannelEvent.detached, callback: self.didChannelLoseState)
        channel.once(ARTChannelEvent.failed, callback: self.didChannelLoseState)
    }
    
    fileprivate func didChannelLoseState(_ error: ARTErrorInfo?) {
        self.channel?.unsubscribe()
        self.ablyRealtime?.connection.once(.connected) { state in
            self.joinChannel()
        }
    }
    
    fileprivate func signalError(_ error: ARTErrorInfo) {
        self.delegate?.positionModel(self, didReceiveError: error)
    }
    
    fileprivate func delay(_ delay: Double, block: @escaping () -> Void) {
        let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: block)
    }
    
    @objc fileprivate func applicationWillResignActiveEventReceived() {
        logXC.debug("applicationWillResignActiveEventReceived")
    }
    
    @objc fileprivate func applicationWillEnterForegroundEventReceived() {
        logXC.debug("applicationWillEnterForegroundEventReceived")
    }
    
    @objc fileprivate func applicationWillTerminateEventReceived() {
        logXC.debug("applicationWillTerminateEventReceived")
    }
    
    @objc fileprivate func applicationDidBecomeActiveEventReceived() {
        logXC.debug("applicationDidBecomeActiveEventReceived")
    }
    
    @objc fileprivate func applicationDidFinishLaunchingEventReceived() {
        logXC.debug("applicationDidFinishLaunchingEventReceived")
    }
    
    @objc fileprivate func applicationDidEnterBackgroundEventReceived() {
        logXC.debug("applicationDidEnterBackgroundEventReceived")
    }

    @objc fileprivate func applicationBackgroundRefreshStatusDidChange() {
        logXC.debug("applicationBackgroundRefreshStatusDidChange")
    }

}
