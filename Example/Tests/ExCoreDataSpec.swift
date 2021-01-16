// https://github.com/Quick/Quick

import Quick
import Nimble
import ExCoreData
import CoreData
import ExLog

@testable import ExCoreData_Example

class ExCoreDataSpec: QuickSpec {
    override func spec() {
        describe("ExCoreData child") {
            context("notInitYet"){
                notInitYet()
            }
            
            context("initializeProcess"){
                initializeProcess()
            }
            
            context("normal"){
                normal()
            }
            
            context("delete"){
                delete()
            }
            
            context("handleTwoExCoreDataClass"){
                handleTwoCoreDataClass()
            }
        }
    }
    
    private func normal(){
        var coreDataContext:NSManagedObjectContext? = nil
        beforeEach {
            coreDataContext = self.initDB()
        }
        
        afterEach {
            ExLog.log("# AfterEach")
            self.cleanDB(ExampleCoreData.self)
        }
        
        it("Static Variable"){
            ExLog.log("# Static Variable")
            expect(ExampleCoreData.getContext()) == coreDataContext
            expect(ExampleCoreData.getCoreDataNum()) == 1
        }
    }
    
    private func notInitYet(){
        beforeEach {
            ExLog.log("#[初期化処理] なにもしない")
        }
        
        afterEach {
            ExLog.log("# AfterEach")
        }
        
        it("Static Variable"){
            ExLog.log("# Static Variable")
            expect(ExampleCoreData.getContext()).to(beNil())
            expect(ExampleCoreData.getCoreDataNum()) == 0
        }
    }
    
    private func initializeProcess(){
        afterEach {
            ExLog.log("# AfterEach")
            self.cleanDB(ExampleCoreData.self)
        }
        
        context("Status"){
            it("initialized"){
                // First Time
                var firstStatus: ExCoreData.Status<NSManagedObjectContext, Error>? = nil
                ExampleCoreData.initInstance { firstStatus = $0 }
                expect(firstStatus).toNotEventually(beNil(), timeout: 5)
                expect("\(firstStatus!)").to(contain("success"))
                
                // Second Time
                var secondStatus: ExCoreData.Status<NSManagedObjectContext, Error>? = nil
                ExampleCoreData.initInstance { secondStatus = $0 }
                expect(secondStatus).toNotEventually(beNil(), timeout: 5)
                expect("\(secondStatus!)").to(contain("initialized"))
            }
            
            it("initializing"){
                // First Time
                var firstStatus: ExCoreData.Status<NSManagedObjectContext, Error>? = nil
                ExampleCoreData.initInstance { firstStatus = $0 }
                
                // Second Time
                var secondStatus: ExCoreData.Status<NSManagedObjectContext, Error>? = nil
                ExampleCoreData.initInstance { secondStatus = $0 }
                
                // Second Timeの結果確認
                expect(secondStatus).toNotEventually(beNil(), timeout: 5)
                expect("\(secondStatus!)").to(contain("initializing"))
                
                // First Timeの結果確認
                expect(firstStatus).toNotEventually(beNil(), timeout: 5)
                expect("\(firstStatus!)").to(contain("success"))
            }
        }
        
        context("Error"){
            class ErrorCoreData: ExCoreData{
                static let packageName = "jp.ky.excoredata.error"
                override var data: ExCoreData.RequiredData {
                    let data = ExCoreData.RequiredData(
                        "Model",
                        ErrorCoreData.packageName,
                        "Error")
                    return data
                }
            }
            
            let applicationDocumentsDirectory:URL = {
                /// Application SupportフォルダーのURLを取得して利用
                let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                let appSupportURL = urls[urls.count - 1]
                return appSupportURL.appendingPathComponent(ErrorCoreData.packageName)
            }()
            
            beforeEach {
                let fileManager = FileManager.default
                ExLog.log(applicationDocumentsDirectory.absoluteString)
                ExLog.log(applicationDocumentsDirectory.path)
                let result = fileManager.createFile(atPath: applicationDocumentsDirectory.path, contents: "test".data(using: .utf8), attributes: nil)
                ExLog.log(result ? "ファイル作成に成功しました" : "ファイル作成に失敗しました")
            }
            
            it("init"){
                var status: ExCoreData.Status<NSManagedObjectContext, Error>? = nil
                ErrorCoreData.initInstance { status = $0 }
                expect(ErrorCoreData.getContext()).to(beNil())
                expect(ErrorCoreData.getCoreDataNum()) == 0
                expect(status).toNotEventually(beNil(), timeout: 5)
                switch status{
                case .failure(let error):
                    expect(error.localizedDescription) == "Failed to initialize the application's saved data"
                default:
                    fail()
                }
                
                expect(ErrorCoreData.getContext()).to(beNil())
                expect(ErrorCoreData.getCoreDataNum()) == 0
            }
            
           // 先にDBファイルを保存するフォルダーのフォルダーに同じ名前のファイルを作成してエラーが発生するケース
        }
        it("On Other Thread"){
            var status: ExCoreData.Status<NSManagedObjectContext, Error>? = nil
            DispatchQueue.global(qos: .userInitiated).async {
                ExampleCoreData.initInstance{status = $0}
            }
            expect(status).toNotEventually(beNil(), timeout:5)
            expect("\(status!)").to(contain("success"))
        }
    }
    
    private func delete(){
        beforeEach {
            _ = self.initDB()
        }
        
        afterEach {
            ExLog.log("# AfterEach")
            self.cleanDB(ExampleCoreData.self)
        }
        
        it("success"){
            expect(ExampleCoreData.getContext()).notTo(beNil())
            expect(ExampleCoreData.getCoreDataNum()) == 1
            
            var processing = true
            ExampleCoreData.deleteStore {
                processing = false
            }
            expect(processing).toEventually(beFalse(), timeout: 5)
            expect(ExampleCoreData.getContext()).to(beNil())
            expect(ExampleCoreData.getCoreDataNum()) == 0
            
        }
    }

    private func handleTwoCoreDataClass(){
        class SecondCoreData: ExCoreData{
            override var data: ExCoreData.RequiredData {
                let data = ExCoreData.RequiredData(
                    "Model",
                    "jp.ky.excoredata",
                    "ExampleSecond")
                return data
            }
        }
        
        beforeEach{
            _ = self.initDB()
        }
        afterEach{
            self.cleanDB(ExampleCoreData.self)
            self.cleanDB(SecondCoreData.self)
        }
        
        it("Create 2 ExCoreData"){
            var status: ExCoreData.Status<NSManagedObjectContext, Error>? = nil
            SecondCoreData.initInstance { status = $0 }
            expect(status).toNotEventually(beNil(), timeout: 5)
            expect("\(status!)").to(contain("success"))
            expect(SecondCoreData.getContext()).notTo(beNil())
            expect(SecondCoreData.getCoreDataNum()) == 2
            expect(ExampleCoreData.getContext()).notTo(beNil())
            expect(ExampleCoreData.getCoreDataNum()) == 2
            
            var deleted = false
            SecondCoreData.deleteStore {
                deleted = true
            }
            expect(deleted).toEventually(beTrue(), timeout: 5)
            expect(SecondCoreData.getContext()).to(beNil())
            expect(SecondCoreData.getCoreDataNum()) == 1
            expect(ExampleCoreData.getContext()).notTo(beNil())
            expect(ExampleCoreData.getCoreDataNum()) == 1
        }
    }
}

/// 各テスト共通に利用する目的のメソッド
extension ExCoreDataSpec{
    private func initDB() -> NSManagedObjectContext{
        var status: ExCoreData.Status<NSManagedObjectContext, Error>? = nil
        ExLog.log("#[初期化処理] contextの生成")
        ExampleCoreData.initInstance { status = $0 }
        expect(status).toNotEventually(beNil(), timeout: 5)
        
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
    
    private func cleanDB<Core: ExCoreData>(_ type: Core.Type){
        guard Core.getContext() != nil else{
            return
        }
        
        var result = false
        Core.deleteStore {
            result = true
        }
        expect(result).toEventually(beTrue(), timeout: 10)
    }
}
