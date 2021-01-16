//
//  User+CoreDataProperties.swift
//  ExCoreData_Example
//
//  Created by yuya on 2021/01/03.
//  Copyright © 2021 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData


extension SimpleUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SimpleUser> {
        return NSFetchRequest<SimpleUser>(entityName: "SimpleUser")
    }

    @NSManaged public var name: String?
    @NSManaged public var id: String?
    @NSManaged public var age: Int32

}
