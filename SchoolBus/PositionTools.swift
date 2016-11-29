//
//  PositionTools.swift
//  SchoolBus
//
//  Created by Paul D Freeman on 29/11/2016.
//  Copyright © 2016 Paul Freeman. All rights reserved.
//

import Foundation
import CoreLocation

open class PositionTools {
    
    open static func Pack(_ location: CLLocation) -> String {
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let locationTimeStamp = dateformatter.string(from: location.timestamp)
        
        let nowDate: Date = Date()
        let now = dateformatter.string(from: nowDate)
        
        var locationString = ""
        locationString = locationString + String(format: "%.6f",location.coordinate.latitude)
        locationString = locationString + "|" + String(format: "%.6f",location.coordinate.longitude)
        locationString = locationString + "|" + String(format: "%.6f",location.horizontalAccuracy)
        locationString = locationString + "|" + String(format: "%.6f", speed(location))
        locationString = locationString + "|" + locationTimeStamp
        locationString = locationString + "|" + now
        
        return locationString
    }
    
    open static func Unpack(_ locationstring: String) -> CLLocation
    {
        let splitArray = locationstring.components(separatedBy: "|")
        
        let lat: Double = Double(splitArray[0] as String)!
        let lon: Double = Double(splitArray[1] as String)!
        let horizAcc: Double = Double(splitArray[2] as String)!
        let speed: Double = Double(splitArray[3] as String)!
        
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let locTS: Date = dateformatter.date(from: splitArray[4] as String!)!
        let  locationCoord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        let location: CLLocation = CLLocation.init(coordinate: locationCoord, altitude: 0, horizontalAccuracy: horizAcc, verticalAccuracy: 1, course: CLLocationDirection.init(), speed: CLLocationSpeed.init(speed/2.23693629), timestamp: locTS)
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

}
