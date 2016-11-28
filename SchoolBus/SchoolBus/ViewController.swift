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


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, PositionModelDelegate {
    
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

    var locationManager: CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    var model: PositionModel!
 
    override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()

    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = CLActivityType.automotiveNavigation
        
        locationManager.distanceFilter = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.startUpdatingLocation()
        
        startLocation = nil
        mapView.delegate = self
   
        let region = MKCoordinateRegionMakeWithDistance((locationManager.location?.coordinate)!,500, 500)
        mapView.setRegion(region, animated: true)

        
        self.model = PositionModel(clientId: "1")
        self.model.delegate = self
        self.model.connect()
        
    }

    internal func sendHeartbeat()
    {
        model.publishMessage("HEARTBEAT")
    }
    
    internal  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        lblLat.text = String(format: "%.6f", latestLocation.coordinate.latitude)
        lblLong.text = String(format: "%.6f",latestLocation.coordinate.longitude)
        lblHorizAcc.text = String(format: "%.6f",latestLocation.horizontalAccuracy)
        lblAltitude.text = String(format: "%.6f",latestLocation.altitude)
        lblVertAcc.text = String(format: "%.6f", latestLocation.verticalAccuracy)
        
        //Get speed - note if horitontal accurancy is greater than 50 it seems very innacurate.
        var speed: CLLocationSpeed = CLLocationSpeed()
        speed = locationManager.location!.speed
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
        logXC.debug("Attempted to transmit " + locationString)
        transmitDate = Date()
        lblDelay.text = "Real time"
        
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        logXC.debug("locationManager Error:" + error.localizedDescription)
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
        logXC.debug("positionModel Error " + error.message)
    }
    
    func positionModel(_ positionModel: PositionModel, didReceiveMessage message: ARTMessage) {
        let s: String = message.data as! String
        logXC.debug("positionModel Received message " + s)
    }
    
    func positionModelDidFinishSendingMessage(_ positionModel: PositionModel) {
        logXC.debug("positionModelDidFinishSendingMessage FinishedSendingMessage")
    }
}

/*
 internal func initNetwork()
 {
 
 reachability.whenReachable = { reachability in
 if reachability.isReachableViaWiFi {
 self.view.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
 } else {
 self.view.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
 }
 self.transmit = true
 }
 
 reachability.whenUnreachable = { reachability in
 self.transmit = false
 self.view.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
 
 }
 
 do {
 try reachability.startNotifier()
 } catch {
 self.view.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
 }
 
 }
 */



