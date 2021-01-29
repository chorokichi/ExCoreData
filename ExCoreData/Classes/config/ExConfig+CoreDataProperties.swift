//
//  ExConfig+CoreDataProperties.swift
//  ExCoreData
//
//  Created by yuya on 2021/01/24.
//
//

import Foundation
import CoreData


extension ExConfig {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExConfig> {
        return NSFetchRequest<ExConfig>(entityName: "ExConfig")
    }

    @NSManaged public var key: String?
    @NSManaged public var value: String?

}
