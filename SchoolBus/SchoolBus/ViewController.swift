//
//  ViewController.swift
//  SchoolBus
//
//  Created by Paul Freeman on 17/09/2016.
//  Copyright © 2016 Paul Freeman. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth
import MapKit
import AblyRealtime
import Foundation
import ReachabilitySwift
import XCGLogger
import UserNotifications
import UserNotificationsUI //framework to customize the notification

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate,ConnectionModelDelegate {
    
    // MARK: Properties
    @IBOutlet weak var lblLong: UILabel!
    @IBOutlet weak var lblHorizAcc: UILabel!
    @IBOutlet weak var lblAltitude: UILabel!
    @IBOutlet weak var lblVertAcc: UILabel!
    @IBOutlet weak var lblLat: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblSpeed: UILabel!
    @IBOutlet weak var lblPositionTime: UILabel!
    

    
    
    var locationManager : CLLocationManager!
    var model: ConnectionModel!
    var regionSet: Bool = false
    var deferringUpdates: Bool = false
    var lastInfoTransmission: Date = Date.init()
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        mapView.delegate = self
        
        //Initiate pub sub connection
        logXC.info("Initiating realtime model, ClientID:" + UIDevice.current.identifierForVendor!.uuidString)
        self.model = ConnectionModel(clientId: UIDevice.current.identifierForVendor!.uuidString)
        self.model.delegate = self
        self.model.connect()
    
        //start monitoring location updates
        initLocationManager()

        //register self as delegate for incoming notification
        UNUserNotificationCenter.current().delegate = self
        
        //Monitor geofences
        PositionTools.startRegionMonitoring(locationManager, mapView)
        
        //start monitoring battery level
        UIDevice.current.isBatteryMonitoringEnabled = true
        let infoString = PositionTools.EncodeInfo()
        logXC.info("Logging info :: " + infoString)
        model.publishMessage(infoString)
        
    }
    
    internal func initLocationManager()
    {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false //when set to true - application wouldn't come out of being paused.
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }


    internal  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        //centre map - once
        if (regionSet == false) {
            let region = MKCoordinateRegionMakeWithDistance((latestLocation.coordinate),3000, 3000)
            mapView.setRegion(region, animated: true)
            regionSet = true
        }
        
        lblLat.text = String(format: "%.6f", latestLocation.coordinate.latitude)
        lblLong.text = String(format: "%.6f",latestLocation.coordinate.longitude)
        lblHorizAcc.text = String(format: "%.6f",latestLocation.horizontalAccuracy)
        lblAltitude.text = String(format: "%.6f",latestLocation.altitude)
        lblVertAcc.text = String(format: "%.6f", latestLocation.verticalAccuracy)
        lblSpeed.text = String(format: "%.0f mph", PositionTools.speed(latestLocation))

        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let locationTimeStamp = dateformatter.string(from: latestLocation.timestamp)
        lblPositionTime.text = locationTimeStamp
        
        //encode location string
        let locationString = PositionTools.EncodePosition(latestLocation)

        //publish to the channel
        model.publishMessage(locationString)
        logXC.verbose("Attempted to transmit " + locationString)
        
        //When was the last time we transmitted state information
        if(abs(Int(lastInfoTransmission.timeIntervalSinceNow)) > 60)    //600
        {
            lastInfoTransmission = Date()
            let infoString = PositionTools.EncodeInfo()
            logXC.verbose("Logging info :: " + infoString)
            model.publishMessage(infoString)
        }

//        //attempt to defer updates.
//        if (self.deferringUpdates == false) {
//            logXC.debug("Attempting to start deferring updates")
//            self.locationManager?.allowDeferredLocationUpdates (untilTraveled: CLLocationDistance(10), timeout: 60)
//            self.deferringUpdates = true
//            logXC.debug("Now with deferred updates")
//        }
        
    }
    
    internal func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        logXC.debug("locationManagerDidPauseLocationUpdates")
    }
    
    internal func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        logXC.debug("locationManagerDidResumeLocationUpdates")
    }

    internal func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        logXC.debug("locationManager didFinishDeferredUpdates!!")
        logXC.debug("locationManager didFinishDeferredUpdates debugDescription" + error.debugDescription)
    }

    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        logXC.error("locationManager Error:" + error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        logXC.error("locationManager Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            logXC.info("Entered Region " + region.identifier)
            let message = PositionTools.EncodeRegion("ENTERED",region.identifier)
            logXC.verbose("Region message: " + message)
            logXC.verbose("Region message about to be sent")
            model.publishMessage(message)
            logXC.verbose("Region message sent")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            logXC.info("Exitted Region " + region.identifier)
            let message = PositionTools.EncodeRegion("EXITTED",region.identifier)
            logXC.verbose("Region message: " + message)
            logXC.verbose("Region message about to be sent")
            model.publishMessage(message)
            logXC.verbose("Region message sent")
        }
    }
    
    internal func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
        mapView.centerCoordinate = userLocation.coordinate
    }
    
    internal func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKCircle.self){
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.lineWidth = 1
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
}


extension ViewController:UNUserNotificationCenterDelegate{
    

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        logXC.debug("Tapped in notification")
    }
    
    //This is key callback to present notification while the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        logXC.debug("Notification being triggered")
        completionHandler( [.alert,.sound,.badge])
    }
    
}



