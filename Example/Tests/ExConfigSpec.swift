//
//  ExConfigSpec.swift
//  ExCoreData_Example
//
//  Created by yuya on 2021/01/24.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import ExCoreData
import CoreData
import ExLog
import CwlPreconditionTesting

@testable import ExCoreData_Example

class ExConfigSpec: QuickSpec {
    var ctx: NSManagedObjectContext!
    
    override func spec(){
        describe("ExRecordsSpec") {
            
            beforeEach {
                self.ctx = ExCoreDataTestUtil<ConfigCoreData>.initDB()
            }
            afterEach {
                ExCoreDataTestUtil<ConfigCoreData>.cleanDB()
            }
            
            context("ExConfig"){
                it("insert"){
                    let config = ExConfig.upsert(key: "Test", val: "Val")
                    expect(config).notTo(beNil())
                    expect(config?.key) == "Test"
                    expect(config?.value) == "Val"
                    expect(try ExConfig.fetchRecords(ConfigCoreData.getContext()!, type:ExConfig.self).count) == 1
                    
                    let config2 = ExConfig.upsert(key: "Test2", val: "Val2")
                    expect(config2).notTo(beNil())
                    expect(config2?.key) == "Test2"
                    expect(config2?.value) == "Val2"
                    expect(try ExConfig.fetchRecords(ConfigCoreData.getContext()!, type:ExConfig.self).count) == 2
                }
                
                it("get"){
                    _ = ExConfig.upsert(key: "Test", val: "Val")
                    _ = ExConfig.upsert(key: "Test2", val: "Val2")
                    expect(ExConfig.get(key: "Test")) == "Val"
                    expect(ExConfig.get(key: "Test2")) == "Val2"
                }
                
                it("update"){
                    _ = ExConfig.upsert(key: "Test", val: "Val")
                    _ = ExConfig.upsert(key: "Test2", val: "Val2")
                    
                    let updatedConfig1 = ExConfig.upsert(key: "Test", val: "Edited")
                    expect(updatedConfig1).notTo(beNil())
                    expect(updatedConfig1?.key) == "Test"
                    expect(updatedConfig1?.value) == "Edited"
                    expect(try ExConfig.fetchRecords(ConfigCoreData.getContext()!, type:ExConfig.self).count) == 2
                }
                
                it("delete"){
                    _ = ExConfig.upsert(key: "Test", val: "Val")
                    _ = ExConfig.upsert(key: "Test2", val: "Val2")
                    
                    ExConfig.delete(key: "Test")
                    let records = try ExConfig.fetchRecords(ConfigCoreData.getContext()!, type:ExConfig.self)
                    expect(records.count) == 1
                    expect(records[0].key) == "Test2"
                    expect(records[0].value) == "Val2"
                }
            }
        }
    }
}
