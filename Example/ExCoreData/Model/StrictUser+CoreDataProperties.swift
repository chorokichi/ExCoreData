//
//  StrictUser+CoreDataProperties.swift
//  ExCoreData_Example
//
//  Created by yuya on 2021/01/20.
//  Copyright © 2021 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData


extension StrictUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StrictUser> {
        return NSFetchRequest<StrictUser>(entityName: "StrictUser")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var age: Int32

}
