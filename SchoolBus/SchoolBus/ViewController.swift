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
import PubNub

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
        locationManager.distanceFilter = 20
        locationManager.startUpdatingLocation()
        startLocation = nil
        
        mapView.delegate = self
   
        let region = MKCoordinateRegionMakeWithDistance((locationManager.location?.coordinate)!,500, 500)
        mapView.setRegion(region, animated: true)

    }
    
    internal  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
 
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        lblLat.text = String(format: "%.4f",
                               latestLocation.coordinate.latitude)
        lblLong.text = String(format: "%.4f",
                                latestLocation.coordinate.longitude)
        lblHorizAcc.text = String(format: "%.4f",
                                         latestLocation.horizontalAccuracy)
        lblAltitude.text = String(format: "%.4f",
                               latestLocation.altitude)
        lblVertAcc.text = String(format: "%.4f",
                                       latestLocation.verticalAccuracy)
        
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
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var client: PubNub
        client = appDelegate.client
        
        
        client.publish("Hello from the PubNub Swift SDK", toChannel: "my_channel",
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
        
        
    }
    
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        debugPrint("Error:" + error.localizedDescription)
        
    }
    
    internal func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
        mapView.centerCoordinate = userLocation.coordinate
    }

    
}

