//
//  PositionTools.swift
//  SchoolBus
//
//  Created by Paul D Freeman on 29/11/2016.
//  Copyright © 2016 Paul Freeman. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import MapKit

open class PositionTools {
    
    
    open static func initLocationManager(_ locationManager: CLLocationManager)
    {

        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false //when set to true - application wouldn't come out of being paused.
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    
    open static func EncodeInfo() -> String {
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let nowDate: Date = Date()
        let now = dateformatter.string(from: nowDate)

        var info = "INFORMATION"
        info = info + "|" + (UIDevice.current.identifierForVendor?.uuidString)!
        info = info + "|" + String(UIDevice.current.systemName)
        info = info + "|" + String(UIDevice.current.systemVersion)
        info = info + "|" + String(format: "%.2f",UIDevice.current.batteryLevel)
        info = info + "|" + now
        
        return info
    }
    
    open static func EncodePosition(_ location: CLLocation) -> String {
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let locationTimeStamp = dateformatter.string(from: location.timestamp)
        
        let nowDate: Date = Date()
        let now = dateformatter.string(from: nowDate)
        
        var locationString = ""
        locationString = "POSITION|"
        locationString = locationString + String(format: "%.6f",location.coordinate.latitude)
        locationString = locationString + "|" + String(format: "%.6f",location.coordinate.longitude)
        locationString = locationString + "|" + String(format: "%.6f",location.horizontalAccuracy)
        locationString = locationString + "|" + String(format: "%.6f", speed(location))
        locationString = locationString + "|" + locationTimeStamp
        locationString = locationString + "|" + now
        
        return locationString
    }
    
    open static func EncodeRegion(_ state: String, _ region: String) -> String {
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let nowDate: Date = Date()
        let now = dateformatter.string(from: nowDate)
        
        var locationString = ""
        locationString = "REGION"
        locationString = locationString + "|" + state
        locationString = locationString + "|" + region
        locationString = locationString + "|" + now
        
        return locationString
    }
    
    
    open static func DecodePosition(_ locationstring: String) -> CLLocation
    {
        let splitArray = locationstring.components(separatedBy: "|")
        var location: CLLocation = CLLocation()
        
        if (splitArray[0] == "POSITION")
        {
        
            let lat: Double = Double(splitArray[1] as String)!
            let lon: Double = Double(splitArray[2] as String)!
            let horizAcc: Double = Double(splitArray[3] as String)!
            let speed: Double = Double(splitArray[4] as String)!
            
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let locTS: Date = dateformatter.date(from: splitArray[5] as String!)!
            let  locationCoord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
                location = CLLocation.init(coordinate: locationCoord, altitude: 0, horizontalAccuracy: horizAcc, verticalAccuracy: 1, course: CLLocationDirection.init(), speed: CLLocationSpeed.init(speed/2.23693629), timestamp: locTS)

        }
        else
        {
            //throw an error
        }
        return location
        
    }
    
    open static func speed(_ location: CLLocation) -> Double {
    
        var speed: CLLocationSpeed = CLLocationSpeed()
        speed = location.speed
        var spd: Double = speed
        if (location.horizontalAccuracy > 50){
            spd = 0
        } else
        {
            spd = spd * 2.23693629
        }
        
        return spd
    }
    
    open static func startRegionMonitoring(_ locationManager: CLLocationManager, _ mapView: MKMapView) {
        
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            logXC.error("We Can't monitor on this device!!!!")
            return
        }
        
        addRegion(locationManager, mapView, "School", 51.163086,0.326432, 150)
        addRegion(locationManager, mapView, "Drop Off", 51.122586, 0.276560, 40)
        addRegion(locationManager, mapView, "Drop Off 1k", 51.122586, 0.276560, 1000)
        addRegion(locationManager, mapView, "Pick Up", 51.120603, 0.272722, 40)
        addRegion(locationManager, mapView, "Home", 51.122039, 0.278730, 40)
        
    }
    
}

func addRegion(_ locationManager: CLLocationManager, _ mapView: MKMapView, _ identity:String, _ lat:Double, _ lon:Double, _ radius:Double)
{
    let region: CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lat, longitude : lon), radius: radius, identifier: identity)
    region.notifyOnEntry = true
    region.notifyOnExit = true
    locationManager.startMonitoring(for: region)
    mapView.add(MKCircle(center: CLLocationCoordinate2D(latitude: lat, longitude : lon), radius: radius))
}

