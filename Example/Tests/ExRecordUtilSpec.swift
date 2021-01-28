//
//  ExRecordUtilSpec.swift
//  ExCoreData_Tests
//
//  Created by yuya on 2021/01/20.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import ExCoreData
import CoreData
import ExLog
import CwlPreconditionTesting

@testable import ExCoreData_Example

class ExRecordUtilSpec: QuickSpec {
    override func spec() {
        describe("ExRecordUtilSpec") {
            var coreDataContext:NSManagedObjectContext? = nil
            beforeEach {
                coreDataContext = ExCoreDataTestUtil<ExampleCoreData>.initDB()
            }
            
            afterEach {
                ExLog.log("# AfterEach")
                ExCoreDataTestUtil<ExampleCoreData>.cleanDB()
            }
            
            context("saveContext"){
                it("just call"){
                    expect{try ExRecordUtil.saveContext(coreDataContext)} == false
                    expect(ExLog.history).to(contain("Context does not have any changes"))
                }
                
                it("normal"){
                    _ = SimpleUser.createEmptyEntity(coreDataContext!, type: SimpleUser.self)
                    expect{try ExRecordUtil.saveContext(coreDataContext)} == true
                }
                
                it("no context"){
                    _ = SimpleUser.createEmptyEntity(coreDataContext!, type: SimpleUser.self)
                    expect{try ExRecordUtil.saveContext(nil)} == false
                }
                
                it("invalid age"){
                    let res = StrictUser.createEmptyEntity(coreDataContext!, type: StrictUser.self)
                    res.getRecord()?.age = -1
                    expect {try ExRecordUtil.saveContext(coreDataContext)}.to(throwError())
                    expect(ExLog.history).to(contain("Unresolved error Error"))
                }
            }
        }
    }
    
    func printStr(str: String) throws {
      if str.isEmpty {
        throw NSError(domain: "the value is empty", code: -1, userInfo: nil)
      } else {
        print(str)
      }
    }
}
