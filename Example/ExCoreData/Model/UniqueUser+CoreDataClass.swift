//
//  UniqueUser+CoreDataClass.swift
//  ExCoreData_Tests
//
//  Created by yuya on 2021/01/18.
//  Copyright © 2021 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData
import ExCoreData

public class UniqueUser: ExRecords {
    /// 主キーとしている属性名
    public class override var PrimaryAttribute: String? {
        return "uniqueId"
    }
}
