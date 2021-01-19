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
import CwlPreconditionTesting

@testable import ExCoreData_Example

class ExRecordsSpec: QuickSpec {
    var ctx: NSManagedObjectContext!
    
    override func spec(){
        describe("ExRecordsSpec") {
            
            beforeEach {
                self.ctx = ExCoreDataTestUtil.initDB()
            }
            afterEach {
                ExCoreDataTestUtil.cleanDB(ExampleCoreData.self)
            }
            
            context("SimpleUser"){
                testSimpleUser()
            }
            
            context("UniqueUser"){
                testUniqueUser()
            }
        }
    }
    
    private func testSimpleUser(){
        context("Fail"){
            it("DueToForgetSave"){
                // CoreDataはNSManagedObjectContextに変更内容が保存されるが、Persistenceに保存する処理をしないと
                let res = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
                expect("\(res.result)") == "New"
                
                // cstを破棄する
                ExampleCoreData.discardStore()
                
                // cstの再取得
                self.ctx = ExCoreDataTestUtil.initDB()
                
                expect{(try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)).count} == 0
            }
            it("Use not difined PrimaryAttribute"){
                var reachedPoint1 = false
                var reachedPoint2 = false
                var reachedPoint3 = false
                expect {
                    reachedPoint1 = true
                    _ = SimpleUser.createEmptyEntity(self.ctx, valueOfPrimaryAttribute: "a", type: SimpleUser.self)
                    reachedPoint2 = true
                    precondition(false, "condition message")
                    reachedPoint3 = true
                }.to(throwAssertion())

                expect(reachedPoint1) == true
                expect(reachedPoint2) == false
                expect(reachedPoint3) == false
            }
        }
        
        it("Add"){
            let res = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
            expect("\(res.result)") == "New"
            res.record.name = "TestName"
            res.record.age = 33
            res.record.id = "TestId"
            
            expect{try res.record.save()} == true
            
            ExampleCoreData.discardStore()
            
            //  取り直し
            self.ctx = ExCoreDataTestUtil.initDB()
            
            var records:[SimpleUser] = []
            expect{
                records = try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)
                return records.count
                } == 1
            
            expect(records[0].name) == "TestName"
            expect(records[0].age) == 33
            expect(records[0].id) == "TestId"
        }
        
        it("Add 10"){
            for _ in 0 ..< 10{
                let res = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
                expect("\(res.result)") == "New"
            }
            expect{ (try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)).count} == 10
        }
        
        it("Delete"){
            let res1 = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
            _ = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
            expect{ (try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)).count} == 2
            expect{try res1.record.save()} == true
            expect{ (try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)).count} == 2
            res1.record.delete()
            expect{try res1.record.save()} == true
            expect{ (try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)).count} == 1
        }
        
        it("DeleteAllRecords"){
            _ = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
            _ = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
            expect{ (try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)).count} == 2
            try? SimpleUser.deleteAllRecords(self.ctx)
            expect{ (try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)).count} == 0
        }
        
        context("Fetch"){
            var records:[SimpleUser] = []
            beforeEach {
                for index in 1 ..< 10 + 1{
                    self.createSimpleUser("Id\(index)", "User\(index)", index)
                }
                records = []
            }
            
            it("simple"){
                expect{
                    records = try SimpleUser.fetchRecords(self.ctx, type: SimpleUser.self)
                    return records.count
                } == 10
            }
            
            it("ascending by age"){
                expect{
                    let sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "age", ascending: true)]
                    records = try SimpleUser.fetchRecords(self.ctx, sortDescriptors: sortDescriptors, type: SimpleUser.self)
                    return records.count
                } == 10
                expect(records[0].age) == 1
            }
            
            it("deascending by age"){
                expect{
                    let sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "age", ascending: false)]
                    records = try SimpleUser.fetchRecords(self.ctx, sortDescriptors: sortDescriptors, type: SimpleUser.self)
                    return records.count
                } == 10
                expect(records[0].age) == 10
            }
            
            it("filter by id"){
                expect{
                    let predicate = NSPredicate(format: "id == %@", "Id5")
                    records = try SimpleUser.fetchRecords(self.ctx, predicate: predicate, type: SimpleUser.self)
                    return records.count
                } == 1
                expect(records[0].id) == "Id5"
            }
        }
    }
    
    private func testUniqueUser(){
        it("Add"){
            let res = UniqueUser.createEmptyEntity(self.ctx, valueOfPrimaryAttribute: "TestId", type: UniqueUser.self)
            expect("\(res.result)") == "New"
            res.record.name = "TestName"
            res.record.age = 33
            expect(res.record.uniqueId) == "TestId"
            
            expect{try res.record.save()} == true
            
            ExampleCoreData.discardStore()
            
            //  取り直し
            self.ctx = ExCoreDataTestUtil.initDB()
            
            var records:[UniqueUser] = []
            expect{
                records = try UniqueUser.fetchRecords(self.ctx, type: UniqueUser.self)
                return records.count
                } == 1
            
            expect(records[0].name) == "TestName"
            expect(records[0].age) == 33
            expect(records[0].uniqueId) == "TestId"
        }
        
        it("FailToAddDueToMissingPrimaryId"){
            var reachedPoint1 = false
            var reachedPoint2 = false
            var reachedPoint3 = false
            expect {
                reachedPoint1 = true
                _ = UniqueUser.createEmptyEntity(self.ctx, type: UniqueUser.self)
                reachedPoint2 = true
                precondition(false, "condition message")
                reachedPoint3 = true
            }.to(throwAssertion())

            expect(reachedPoint1) == true
            expect(reachedPoint2) == false
            expect(reachedPoint3) == false
        }
        
        context("10Users"){
            beforeEach {
                for index in 1 ..< 10 + 1{
                    self.createUniqueUser("Id\(index)", "User\(index)", index)
                }
            }
            it("Update"){
                expect{ (try UniqueUser.fetchRecords(self.ctx, type: UniqueUser.self)).count} == 10
                let res = UniqueUser.createEmptyEntity(self.ctx, valueOfPrimaryAttribute: "Id1", type: UniqueUser.self)
                expect("\(res.result)") == "Updated"
                expect(res.record.name) == "User1"
                expect(res.record.age) == 1
                expect{ (try UniqueUser.fetchRecords(self.ctx, type: UniqueUser.self)).count} == 10
            }
            
            it("FetchExistingOneRecord"){
                expect{ (try UniqueUser.fetchRecords(self.ctx, type: UniqueUser.self)).count} == 10
                let record = UniqueUser.fetchOneRecord(self.ctx, valueOfPrimaryAttribute: "Id5", type: UniqueUser.self)
                expect(record).notTo(beNil())
                expect(record?.uniqueId) == "Id5"
                expect(record?.name) == "User5"
                expect(record?.age) == 5
            }
            
            it("FetchNotExistingOneRecord"){
                expect{ (try UniqueUser.fetchRecords(self.ctx, type: UniqueUser.self)).count} == 10
                let record = UniqueUser.fetchOneRecord(self.ctx, valueOfPrimaryAttribute: "xxxx", type: UniqueUser.self)
                expect(record).to(beNil())
            }
        }
    }
    
    private func createSimpleUser(_ id: String, _ name:String, _ age:Int){
        let res = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
        res.record.id = id
        res.record.name = name
        res.record.age = Int32(age)
    }
    
    private func createUniqueUser(_ id: String, _ name:String, _ age:Int){
        let res = UniqueUser.createEmptyEntity(self.ctx, valueOfPrimaryAttribute: id, type: UniqueUser.self)
        res.record.name = name
        res.record.age = Int32(age)
    }
}
