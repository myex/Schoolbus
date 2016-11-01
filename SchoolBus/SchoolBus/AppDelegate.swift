//
//  AppDelegate.swift
//  SchoolBus
//
//  Created by Paul Freeman on 17/09/2016.
//  Copyright © 2016 Paul Freeman. All rights reserved.
//

import UIKit
import PubNub

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PNObjectEventListener {

    var window: UIWindow?

    // Stores reference on PubNub client to make sure what it won't be released.
    var client: PubNub!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        self.client.logger.enabled = true
        self.client.logger.setLogLevel(PNLogLevel.PNVerboseLogLevel.rawValue)
        
        
        // Initialize and configure PubNub client instance
        let configuration = PNConfiguration(publishKey: "pub-c-e0910a1e-fd8e-45ff-b32a-e393642e68bd",
                                            subscribeKey: "sub-c-5b3a15ec-a003-11e6-96cb-02ee2ddab7fe")
        
        self.client = PubNub.clientWithConfiguration(configuration)
        
        
        self.client.addListener(self)
        
        // Subscribe to demo channel with presence observation
        self.client.subscribeToChannels(["demo sub"], withPresence: true)
        
        self.client.publish("Hello from the PubNub Swift SDK", toChannel: "demo pub ",
                       compressed: false, withCompletion: { (status) in
                        
                        if !status.isError {
                            debugPrint("success")
                            // Message successfully published to specified channel.
                        }
                        else{
                            debugPrint("error")
                            debugPrint(status.description)
                            debugPrint(status.debugDescription)
                            
                            /**
                             Handle message publish error. Check 'category' property to find
                             out possible reason because of which request did fail.
                             Review 'errorData' property (which has PNErrorData data type) of status
                             object to get additional information about issue.
                             
                             Request can be resent using: status.retry()
                             */
                        }
        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    


}

