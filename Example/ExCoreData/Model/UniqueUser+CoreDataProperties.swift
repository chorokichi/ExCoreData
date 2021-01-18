//
//  UniqueUser+CoreDataProperties.swift
//  ExCoreData_Tests
//
//  Created by yuya on 2021/01/18.
//  Copyright © 2021 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData


extension UniqueUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UniqueUser> {
        return NSFetchRequest<UniqueUser>(entityName: "UniqueUser")
    }

    @NSManaged public var uniqueId: String?
    @NSManaged public var name: String?
    @NSManaged public var age: Int32

}
