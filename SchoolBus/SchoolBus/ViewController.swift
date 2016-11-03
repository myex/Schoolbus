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


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    // MARK: Properties

    @IBOutlet weak var lblLong: UILabel!
    @IBOutlet weak var lblHorizAcc: UILabel!
    @IBOutlet weak var lblAltitude: UILabel!
    @IBOutlet weak var lblVertAcc: UILabel!
    @IBOutlet weak var lblLat: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lblSpeed: UILabel!
   
    var client: ARTRealtime!
    
    var locationManager: CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!

        override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        //locationManager.distanceFilter = 0
        locationManager.startUpdatingLocation()
        startLocation = nil
        
        mapView.delegate = self
        
   
        let region = MKCoordinateRegionMakeWithDistance((locationManager.location?.coordinate)!,500, 500)
        mapView.setRegion(region, animated: true)

        client = ARTRealtime(key: "QGOsVA.UnM4VQ:YuOO9DIWTgs2BcPZ")
        
    }
    
    internal  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
 
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        
        
        lblLat.text = String(format: "%.6f", latestLocation.coordinate.latitude)
        lblLong.text = String(format: "%.6f",latestLocation.coordinate.longitude)
        lblHorizAcc.text = String(format: "%.6f",latestLocation.horizontalAccuracy)
        lblAltitude.text = String(format: "%.6f",latestLocation.altitude)
        lblVertAcc.text = String(format: "%.6f", latestLocation.verticalAccuracy)
        
        var speed: CLLocationSpeed = CLLocationSpeed()
        speed = locationManager.location!.speed
        lblSpeed.text = String(format: "%.0f mph", speed * 2.23693629)
        
        if startLocation == nil {
            startLocation = latestLocation
        }
        
        let distanceBetween: CLLocationDistance =
            latestLocation.distance(from: startLocation)
        
        lblDistance.text = String(format: "%.2f", distanceBetween)
        
        startLocation = latestLocation
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "MMMM dd yyyy hh:mm:ss.SSS"
        let locationTimeStamp = dateformatter.string(from: latestLocation.timestamp)
        
        let now = dateformatter.string(from: NSDate() as Date)
        //dateformatter.string(from: NSDate.date())

        //build up the location information to publish
        var locationString = ""
        locationString = locationString + String(format: "%.6f",latestLocation.coordinate.latitude)
        locationString = locationString + "|" + String(format: "%.6f",latestLocation.coordinate.longitude)
        locationString = locationString + "|" + String(format: "%.6f",latestLocation.horizontalAccuracy)
        locationString = locationString + "|" + String(format: "%.0f mph", speed * 2.23693629)
        locationString = locationString + "|" + locationTimeStamp
        locationString = locationString + "|" + now
        
        //publish to the channel
        let channel = client.channels.get("Position")
        channel.publish("Location", data: locationString)
        debugPrint(locationString)
        
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        debugPrint("Error:" + error.localizedDescription)
        
    }
    
    internal func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
        debugPrint("mapview recentred")
        mapView.centerCoordinate = userLocation.coordinate
    }

}

