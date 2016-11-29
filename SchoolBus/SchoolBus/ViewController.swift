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


class ViewController: UIViewController, MKMapViewDelegate, PositionModelDelegate, CLLocationManagerDelegate {
    
    // MARK: Properties

    @IBOutlet weak var lblLong: UILabel!
    @IBOutlet weak var lblHorizAcc: UILabel!
    @IBOutlet weak var lblAltitude: UILabel!
    @IBOutlet weak var lblVertAcc: UILabel!
    @IBOutlet weak var lblLat: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblSpeed: UILabel!
    @IBOutlet weak var lblDelay: UILabel!
    @IBOutlet weak var lblPosTime: UILabel!
    
    //declare this property where it won't go out of scope relative to your listener
    var transmitDate: Date!
    var locationManager : CLLocationManager!
    var startLocation: CLLocation!
    var model: PositionModel!
    var regionSet: Bool = false
    var deferringUpdates: Bool = false
    
 
    override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()

    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
   
        startLocation = nil
        mapView.delegate = self
        
        self.model = PositionModel(clientId: UIDevice.current.identifierForVendor!.uuidString)
        logXC.info("Initiating realtime model, ClientID:" + UIDevice.current.identifierForVendor!.uuidString)
        
        self.model.delegate = self
        self.model.connect()
        
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
        
        if (regionSet == false) {
            let region = MKCoordinateRegionMakeWithDistance((latestLocation.coordinate),500, 500)
            mapView.setRegion(region, animated: true)
            regionSet = true
        }
        
        lblLat.text = String(format: "%.6f", latestLocation.coordinate.latitude)
        lblLong.text = String(format: "%.6f",latestLocation.coordinate.longitude)
        lblHorizAcc.text = String(format: "%.6f",latestLocation.horizontalAccuracy)
        lblAltitude.text = String(format: "%.6f",latestLocation.altitude)
        lblVertAcc.text = String(format: "%.6f", latestLocation.verticalAccuracy)
        
        //Get speed - note if horitontal accurancy is greater than 50 it seems very innacurate.
        var speed: CLLocationSpeed = CLLocationSpeed()
        speed = latestLocation.speed
        var spd: Double = speed
        if (latestLocation.horizontalAccuracy > 50){
            spd = 0
        }
        
        lblSpeed.text = String(format: "%.0f mph", spd * 2.23693629)
        
        if startLocation == nil {
            startLocation = latestLocation
        }
        
        let distanceBetween: CLLocationDistance =
            latestLocation.distance(from: startLocation)
        
        lblDistance.text = String(format: "%.2f", distanceBetween)
        
        startLocation = latestLocation
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let locationTimeStamp = dateformatter.string(from: latestLocation.timestamp)
        lblPosTime.text = locationTimeStamp
        
        let nowDate: Date = Date()
        let now = dateformatter.string(from: nowDate)
  
        //build up the location information to publish
        var locationString = ""
        locationString = locationString + String(format: "%.6f",latestLocation.coordinate.latitude)
        locationString = locationString + "|" + String(format: "%.6f",latestLocation.coordinate.longitude)
        locationString = locationString + "|" + String(format: "%.6f",latestLocation.horizontalAccuracy)
        locationString = locationString + "|" + String(format: "%.6f", spd * 2.23693629)
        locationString = locationString + "|" + locationTimeStamp
        locationString = locationString + "|" + now
        
        //publish to the channel
        model.publishMessage(locationString)
        logXC.verbose("Attempted to transmit " + locationString)
        transmitDate = Date()
        lblDelay.text = "Real time"
        
        
        if (self.deferringUpdates == false) {
            logXC.debug("Attempting to start deferring updates")
            
            self.locationManager?.allowDeferredLocationUpdates (untilTraveled: CLLocationDistance(10), timeout: 60)
            
            self.deferringUpdates = true
            logXC.debug("Now with deferred updates")
        }
        
        
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
    
    internal func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
        mapView.centerCoordinate = userLocation.coordinate
    }

    

}

extension PositionModelDelegate {
    func positionModel(_ positionModel: PositionModel, connectionStateChanged: ARTConnectionStateChange) {
        if (connectionStateChanged.current == ARTRealtimeConnectionState.closed)
        {
        }
        logXC.debug("positionModel connectionstatechanged ")
    }
    
    func positionModel(_ positionModel: PositionModel, didReceiveError error: ARTErrorInfo) {
        logXC.error("positionModel Error " + error.message)
    }
    
    func positionModel(_ positionModel: PositionModel, didReceiveMessage message: ARTMessage) {
        let s: String = message.data as! String
        logXC.verbose("positionModel Received message " + s)
    }
    
    func positionModelDidFinishSendingMessage(_ positionModel: PositionModel) {
        logXC.verbose("positionModelDidFinishSendingMessage FinishedSendingMessage")
    }
}



