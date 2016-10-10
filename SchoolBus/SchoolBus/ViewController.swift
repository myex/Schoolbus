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

class ViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var txtLog: UITextView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        print("hello there")
        var r = Location.getLocation(withAccuracy: .any, frequency: .oneShot, timeout: nil, onSuccess: { (loc) in
            print("loc \(loc)")
        }) { (last, err) in
            print("err \(err)")
        }
        r.onAuthorizationDidChange = { newStatus in
            print("New status \(newStatus)")
        }
        print("done!!!!")
    }
        

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: Actions
    
    @IBAction func btnStartClicked(_ sender: UIButton) {
        txtLog.text = "Start locating\n" + txtLog.text
    }

    @IBAction func btnStopClicked(_ sender: UIButton) {
        txtLog.text = "Stopping locating\n" + txtLog.text
    }
}

