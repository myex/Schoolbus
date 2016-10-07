//
//  ViewController.swift
//  SchoolBus
//
//  Created by Paul Freeman on 17/09/2016.
//  Copyright © 2016 Paul Freeman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var txtLog: UITextView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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

