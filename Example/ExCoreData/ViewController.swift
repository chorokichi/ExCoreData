//
//  ViewController.swift
//  ExCoreData
//
//  Created by Jirokichi on 01/02/2021.
//  Copyright (c) 2021 Jirokichi. All rights reserved.
//

import UIKit
import CoreData
import ExLog

class ViewController: UIViewController {

    @IBOutlet weak var loadingStachView: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startLoad()
//        ExampleCoreData.initInstance { (context: NSManagedObjectContext?) in
//            ExLog.log()
//            self.endLoad()
//        }
    }
    
    private func startLoad(){
        loadingStachView.isHidden = false
    }
    
    private func endLoad(){
        loadingStachView.isHidden = true
    }
}

