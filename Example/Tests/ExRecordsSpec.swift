//
//  ExRecordsSpec.swift
//  ExCoreData_Tests
//
//  Created by yuya on 2021/01/17.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import ExCoreData
import CoreData
import ExLog

@testable import ExCoreData_Example

class ExRecordsSpec: QuickSpec {
    override func spec(){
        describe("ExRecordsSpec") {
            var ctx: NSManagedObjectContext!
            beforeEach {
                ctx = ExCoreDataTestUtil.initDB()
            }
            afterEach {
                ExCoreDataTestUtil.cleanDB(ExampleCoreData.self)
            }
            
            context("SimpleUser"){
            
                it("Add"){
                    let res = SimpleUser.createEmptyEntity(ctx, type: SimpleUser.self)
                    expect("\(res.result)") == "New"
                    res.record.name = "TestName"
                    res.record.age = 33
                    res.record.id = "TestId"
                    
                    var records:[SimpleUser] = []
                    expect{
                        records = try SimpleUser.fetchRecords(ctx, type: SimpleUser.self)
                        return records.count
                        } == 1
                    
                    expect(records[0].name) == "TestName"
                    expect(records[0].age) == 33
                    expect(records[0].id) == "TestId"
                }
                
                it("Add 10"){
                    for _ in 0 ..< 10{
                        let res = SimpleUser.createEmptyEntity(ctx, type: SimpleUser.self)
                        expect("\(res.result)") == "New"
                    }
                    expect{ (try SimpleUser.fetchRecords(ctx, type: SimpleUser.self)).count} == 10
                }
                
                it("Update"){
                    let res = SimpleUser.createEmptyEntity(ctx, type: SimpleUser.self)
                    expect("\(res.result)") == "New"
                    expect{ (try SimpleUser.fetchRecords(ctx, type: SimpleUser.self)).count} == 1
                }
                
                
            }
        }
    }
}
