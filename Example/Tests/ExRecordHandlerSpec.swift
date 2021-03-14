//
//  ExRecordHandlerSpec.swift
//  ExCoreData_Tests
//
//  Created by yuya on 2021/03/13.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import ExCoreData
import CoreData
import ExLog
import CwlPreconditionTesting

@testable import ExCoreData_Example

class ExRecordHandlerSpec: QuickSpec {
    var ctx: NSManagedObjectContext!
    
    override func spec(){
        describe("ExRecordsSpec") {
            
            beforeEach {
                self.ctx = ExCoreDataTestUtil<ExampleCoreData>.initDB()
            }
            afterEach {
                ExCoreDataTestUtil<ExampleCoreData>.cleanDB()
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
            it("Use not difined PrimaryAttribute"){
                let res = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
                expect{try res.getRecord()?.save()} == true
                // キャッシュ削除
                ExampleCoreData.discardStore()
                //  取り直し
                self.ctx = ExCoreDataTestUtil<ExampleCoreData>.initDB()
                
                //　fetchOneRecordでデータ取得
                expect(ExRecordHandler<SimpleUser>().fetchOneRecord(self.ctx, valueOfPrimaryAttribute: "dummy")).to(throwAssertion())
            }
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
                    records = try ExRecordHandler<SimpleUser>().fetchRecords(self.ctx)
                    return records.count
                } == 10
            }
            
            it("ascending by age"){
                expect{
                    let sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "age", ascending: true)]
                    records = try ExRecordHandler<SimpleUser>().fetchRecords(self.ctx, sortDescriptors: sortDescriptors)
                    return records.count
                } == 10
                expect(records[0].age) == 1
            }
            
            it("deascending by age"){
                expect{
                    let sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "age", ascending: false)]
                    records = try ExRecordHandler<SimpleUser>().fetchRecords(self.ctx, sortDescriptors: sortDescriptors)
                    return records.count
                } == 10
                expect(records[0].age) == 10
            }
            
            it("filter by id"){
                expect{
                    let predicate = NSPredicate(format: "id == %@", "Id5")
                    records = try ExRecordHandler<SimpleUser>().fetchRecords(self.ctx, predicate: predicate)
                    return records.count
                } == 1
                expect(records[0].id) == "Id5"
            }
        }
    }
    
    private func testUniqueUser(){
        context("Fail"){
            it("Fetch"){
                self.createUniqueUser("IdFetch", "UserFetch", 1)
                expect{try TestRecordHandler<UniqueUser>().fetch(self.ctx, request: SimpleUser.fetchRequest()) }.to(throwError())
                expect{TestRecordHandler<UniqueUser>().fetchOneRecord(self.ctx, valueOfPrimaryAttribute:"IdFetch") }.to(throwAssertion())
            }
            
            it("Create same key records"){
                // ひとつ目のレコード作成
                self.createUniqueUser("IdFetch", "UserFetch", 1)
                
                // 無理やり同じIDのレコード作成
                guard let record: UniqueUser = NSEntityDescription.insertNewObject(forEntityName: "UniqueUser", into: self.ctx) as? UniqueUser else {
                    fatalError("record should not be nil.")
                }
                record.uniqueId = "IdFetch"
                record.name = "UserFetch2"
                record.age = 2
                
                expect{ExRecordHandler<UniqueUser>().fetchOneRecord(self.ctx, valueOfPrimaryAttribute:"IdFetch") }.to(throwAssertion())
            }
        }
        
        context("10Users"){
            beforeEach {
                for index in 1 ..< 10 + 1{
                    self.createUniqueUser("Id\(index)", "User\(index)", index)
                }
            }
            
            it("FetchExistingOneRecord"){
                expect{ (try ExRecordHandler<UniqueUser>().fetchRecords(self.ctx)).count} == 10
                let record = ExRecordHandler<UniqueUser>().fetchOneRecord(self.ctx, valueOfPrimaryAttribute: "Id5")
                expect(record).notTo(beNil())
                expect(record?.uniqueId) == "Id5"
                expect(record?.name) == "User5"
                expect(record?.age) == 5
            }
            
            it("FetchNotExistingOneRecord"){
                expect{ (try ExRecordHandler<UniqueUser>().fetchRecords(self.ctx)).count} == 10
                let record = ExRecordHandler<UniqueUser>().fetchOneRecord(self.ctx, valueOfPrimaryAttribute: "xxxx")
                expect(record).to(beNil())
            }
        }
    }
    
    private func createSimpleUser(_ id: String, _ name:String, _ age:Int){
        let res = SimpleUser.createEmptyEntity(self.ctx, type: SimpleUser.self)
        let record = res.getRecord()!
        record.id = id
        record.name = name
        record.age = Int32(age)
    }
    
    private func createUniqueUser(_ id: String, _ name:String, _ age:Int){
        let res = UniqueUser.createEmptyEntity(self.ctx, valueOfPrimaryAttribute: id, type: UniqueUser.self)
        let record = res.getRecord()!
        record.name = name
        record.age = Int32(age)
    }
}

class TestRecordHandler<R: ExRecords>: ExRecordHandler<R>{
    override func fetch(_ context: NSManagedObjectContext, request: NSFetchRequest<R>) throws -> [R]{
        throw TestError.Fetch
    }
    
    enum TestError: Error{
        case Fetch
    }
}
