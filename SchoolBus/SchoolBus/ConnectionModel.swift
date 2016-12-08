//
//  ConnectionModel.swift
//  SchoolBus
//
//  Created by Paul Freeman on 14/11/2016.
//  Copyright © 2016 Paul Freeman. All rights reserved.
//

import Foundation
import AblyRealtime

public protocol ConnectionModelDelegate {
    
//    func connectionModel(_ connectionModel: ConnectionModel, connectionStateChanged:ARTConnectionStateChange)
//    func connectionModelDidFinishSendingMessage(_ connectionModel: ConnectionModel, _ message: String)
    func connectionModel(_ connectionModel: ConnectionModel, didReceiveMessage message: ARTMessage)
//    func connectionModel(_ connectionModel: ConnectionModel, didReceiveError error: ARTErrorInfo)
}

open class ConnectionModel {
    fileprivate var ablyClientOptions: ARTClientOptions
    fileprivate var ablyRealtime: ARTRealtime?
    fileprivate var channelLocation: ARTRealtimeChannel?
    
    open var clientId: String
    open var delegate: ConnectionModelDelegate?
    var subscribe: Bool = false
    
    public init(clientId: String, subscribe:Bool) {
        
        self.clientId = clientId
        self.subscribe = subscribe
        
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

        self.ablyRealtime = nil
        self.ablyRealtime = ARTRealtime(key: "QGOsVA.UnM4VQ:YuOO9DIWTgs2BcPZ")
       
        channelLocation = self.ablyRealtime?.channels.get("Position")
        
        self.ablyRealtime?.connection.on { stateChange in
            if let stateChange = stateChange {
                
                logXC.verbose("connection state change: " + stateChange.debugDescription)
                
                switch stateChange.current {
                case .connected:
                    logXC.debug("state change to connected")
                case .disconnected:
                    logXC.debug("state change to disconnected")
                    self.attemptClientReconnect(10)
                case .suspended:
                    logXC.debug("state change to suspended")
                    self.attemptClientReconnect(15)
                case .closed:
                    logXC.debug("state change to closed")
                    self.attemptClientReconnect(20)
                case .failed:
                    logXC.debug("state change to failed")
                    self.attemptClientReconnect(20)
                    
                default:
                    break
                }
            }
        }
        
        _ = channelLocation?.on { error in
            logXC.verbose("channel state is : \(self.channelLocation?.state), error description is \(error.debugDescription)")
            if (self.channelLocation?.state == ARTRealtimeChannelState.detached || self.channelLocation?.state == ARTRealtimeChannelState.failed)
            {
                logXC.verbose("attempting to rejoin channel")
                self.joinChannel()
            }
            
           
        }

        
        channelLocation?.on(.initialized) { error in
            logXC.verbose("channel initialized: ")
        }

        channelLocation?.on(.attaching) { error in
            logXC.verbose("channel attaching: ")
        }
        
        channelLocation?.on(.attached) { error in
            logXC.verbose("channel attached: ")
        }
        
        channelLocation?.on(.detaching) { error in
            logXC.verbose("channel detaching: " + error.debugDescription)
        }
        
        channelLocation?.on(.detached) { error in
            logXC.error("channel detached: " + error.debugDescription)
            self.joinChannel()
        }

        channelLocation?.on(.error) { error in
            logXC.error("channel error: " + error.debugDescription)
            self.joinChannel()
        }
        
        channelLocation?.on(.failed) { error in
            logXC.error("channel failed: " + error.debugDescription)
            self.ablyRealtime?.connect()
            self.joinChannel()
        }

        self.ablyRealtime?.connect()
        
        self.joinChannel()

    }
    
    // Leaves channel by disconnecting from Ably
    open func disconnect() {
        self.ablyRealtime?.connection.close()
    };
    
    open func publishMessage(_ message: String) -> Bool {
        
        //assume success!
        var success: Bool = true
        
        if(self.ablyRealtime?.connection.state == ARTRealtimeConnectionState.connected)
        {
            
            if (self.channelLocation?.state == ARTRealtimeChannelState.attached){
        
                logXC.verbose("Attempting to PublishMessage :" + message)
                self.channelLocation?.publish(self.clientId, data: message, clientId: self.clientId) { error in
                
                    guard error == nil else {
                        //Let the world know there was an error
                        logXC.error("Error Publishing Message" + (error?.message)! + "\n" + error.debugDescription)
                    
                        //now try and reconnect
                        self.joinChannel()
                        success = false
                        return
                    }
                }
            }
            else
            {
                logXC.verbose("Channel not attached - will not attempt to publish message.")
                success = false
            }
        }
        else {
            logXC.verbose("Client not connected - will not attempt to publish message.")
            success = false
        }
        if (success == true) {
            logXC.verbose("PublishMessage Success:" + message)
        }
        return success
    }
    
    
    fileprivate func attemptClientReconnect(_ delay: Double) {
        logXC.verbose("Starting delay of " + String(delay))
         self.delay(delay) {
            self.connect()
         }
    }
    
    fileprivate func joinChannel() {
        
        logXC.verbose("Joining channel")
        guard let channel = self.channelLocation else { return }
        
        if (subscribe) {
            channel.unsubscribe()
        }
        channel.detach()
        channel.attach()
        if (subscribe) {
            channel.subscribe { self.delegate?.connectionModel(self, didReceiveMessage: $0) }
        }
        
        logXC.verbose("Channel should now be connected")
    }
    
    fileprivate func delay(_ delay: Double, block: @escaping () -> Void) {
        let time = DispatchTime.now() + Double(Int64((delay * 333.333333) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
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
