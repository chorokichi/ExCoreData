//
//  ExCoreDataMessureTests.swift
//  ExCoreData_Tests
//
//  Created by yuya on 2021/01/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
import ExCoreData
import CoreData
import ExLog
@testable import ExCoreData_Example

class ExCoreDataMessureTests: XCTestCase {
    override func tearDownWithError() throws {
 
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        var count = 1
        self.measure {
            ExLog.important("\(String(format: "%2d回目...", count))")
            let exp = self.expectation(description: "Performance")
            exp.expectedFulfillmentCount = 3
            var status1: ExCoreDataInitStatus<NSManagedObjectContext, Error>? = nil
            var status2: ExCoreDataInitStatus<NSManagedObjectContext, Error>? = nil
            var status3: ExCoreDataInitStatus<NSManagedObjectContext, Error>? = nil
            DispatchQueue.main.async {
                ExLog.log(Thread.current)
                ExampleCoreData.initInstance { status in
                    status1 = status
                    exp.fulfill()
                }
            }
            DispatchQueue.main.async {
                ExLog.log(Thread.current)
                ExampleCoreData.initInstance { status in
                    status2 = status
                    exp.fulfill()
                }
            }
            DispatchQueue.main.async {
                ExLog.log(Thread.current)
                ExampleCoreData.initInstance { status in
                    status3 = status
                    exp.fulfill()
                }
            }
            
            wait(for: [exp], timeout: 10.0)
            
            var list = [status1!, status2!, status3!]
            list.removeAll { "\(String(describing: $0))".contains("success") }
            list.removeAll { "\(String(describing: $0))".contains("initializing") }
            XCTAssertEqual(list.count, 0, "\(list)")
            
            clean()
            count = count + 1
        }
    }

    
    private func clean(){
        ExLog.log("tearDownWithError")
        guard ExampleCoreData.getContext() != nil else{
            return
        }
        
        let exp = self.expectation(description: "Performance")
        
        ExampleCoreData.deleteStore {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10.0)
    }
}
