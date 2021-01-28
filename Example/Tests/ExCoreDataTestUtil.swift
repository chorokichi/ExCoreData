//
//  ExCoreDataTestUtil.swift
//  ExCoreData_Tests
//
//  Created by yuya on 2021/01/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//
import Quick
import Nimble
import ExCoreData
import CoreData
import ExLog

@testable import ExCoreData_Example

/// 各テスト共通に利用する目的のメソッド
struct ExCoreDataTestUtil<Core: ExCoreData> {
    static func initDB() -> NSManagedObjectContext{
        var status: ExCoreDataInitStatus<NSManagedObjectContext, Error>? = nil
        ExLog.log("#[初期化処理] contextの生成")
        Core.initInstance { status = $0 }
        expect(status).toNotEventually(beNil(), timeout: .seconds(5))
        
        let coreDataContext:NSManagedObjectContext?
        switch status{
        case .success(let context):
            coreDataContext = context
        default:
            fail()
            coreDataContext = nil
        }
        ExLog.log("# contextの生成終: \(String(describing: status))")
        return coreDataContext!
    }
        
    static func cleanDB(){
        guard Core.getContext() != nil else{
            return
        }
        
        var result = false
        Core.deleteStore {
            result = true
        }
        expect(result).toEventually(beTrue(), timeout: .seconds(10))
    }
}
