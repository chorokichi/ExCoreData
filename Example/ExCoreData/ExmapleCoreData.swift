//
//  ExmapleCoreData.swift
//  ExCoreData_Example
//
//  Created by yuya on 2021/01/03.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import ExCoreData

class ExampleCoreData: ExCoreData{
    override var data: ExCoreData.RequiredData {
        let data = ExCoreData.RequiredData(
            "Model",
            "jp.ky.excoredata",
            "Example")
        return data
    }
}
