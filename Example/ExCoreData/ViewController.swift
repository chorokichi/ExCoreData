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
import ExCoreData

class ViewController: UIViewController {

    @IBOutlet weak var loadingStachView: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startLoad()
//        ExampleCoreData.initInstance { (context: NSManagedObjectContext?) in
//            ExLog.log()
//            self.endLoad()
//        }
        
        ExampleCoreData.initInstance { (status: ExCoreDataInitStatus<NSManagedObjectContext, Error>) in
            switch status{
            case .failure(let error):
                ExLog.error(error)
                ExLog.log("予期しないエラーが発生した")
            case .initialized:
                ExLog.error("アプリ起動後にすでに初期化済みもしくは削除済みである")
            case .initializing:
                ExLog.error("アプリ起動後に別の箇所でExampleCoreData.initInstanceを呼び出してまだ初期化中である")
            case .success(let context):
                ExLog.log("初期化完了。作成されたcontextは次の通りである：\(context)")
            }
            
            self.endLoad()
        }
    }
    
    private func startLoad(){
        loadingStachView.isHidden = false
    }
    
    private func endLoad(){
        loadingStachView.isHidden = true
    }
}

