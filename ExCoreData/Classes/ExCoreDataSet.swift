//
//  ExCoreDataSet.swift
//  DKLibrary
//
//  Created by yuya on 2017/06/17.
//  Copyright © 2017年 yuya. All rights reserved.
//

import CoreData
import ExLog

/// コアデータを操作するための設定を簡易化してくれるクラス。
/// 
/// 継承した子クラスで静的メソッドinitInstanceによってインタンスを
/// 作成することで、永続ファイルと関連したメインスレッド用NSManagedContextを
/// ```
/// {子クラス名}.getContext
/// ```
/// で取得できる
/// * 注意:
/// 1. このクラスは直接利用せず、継承した子クラスを利用すること
/// 2. 子クラスではdataをオーバーライドしてRequiredDataを設定すること
/// 3. 子クラスであってもイニシャライザは外から呼び出してはならない。代わりにinitInstanceを利用すること。
open class ExCoreData {
    fileprivate static let LogTag = "[ExCoreData]"
    
    public typealias RequiredData = (xcDataModelName: String, packageName: String, storeDataName: String)
    public enum Status: String {
        case NotInitilazed
        case Initializing
        case Initilazed
    }
    
    ///
    /// 子クラスで必ず実装する必要がある変数
    ///
    open var data: ExCoreData.RequiredData {
        ExLog.error("\(ExCoreData.LogTag)Not Defined in Sub class")
        fatalError("Not Defined in Sub class")
    }
    
    /// DKCoreDataを継承したクラスでinitInstanceしたときに保存される配列
    /// ひとつのクラスでは一つしか作成されない。
    private static var _Instance: [ExCoreData] = []
    /// DKCoreDataのインスタンスを取得するメソッド
    private static func getInstance() -> ExCoreData? {
        for instance in self._Instance where self == type(of: instance) {
            // サブクラスで呼び出すとそのサブクラスと関係したインスタンスのみ取得される仕様
            return instance
        }
        ExLog.log("\(ExCoreData.LogTag)Not found any instances related with \"\(self)\". The number of _Instance is \(_Instance.count).")
        return nil
    }
    
    public static func getCoreDataNum() -> Int {
        return self._Instance.count
    }
    
    var context: NSManagedObjectContext?
    
    /// このメソッドは呼び出してはいけない！！！！
    /// 補足：本当はprivateにしたいがinitInstanceメソッドで初期化する際にpublicにしておく必要がある()
    public required init(completionHandler: @escaping (NSManagedObjectContext?) -> Void) {
        ExLog.log("\(ExCoreData.LogTag)\"\(self)\"の初期化処理開始...")
        ExCoreData.createInstance(requiredData: self.data) { (result: ExCoreDataResult<NSManagedObjectContext, Error>) in
            ExLog.log("\(ExCoreData.LogTag)**** callback method")
            switch result {
            case .failure:
                ExLog.error("\(ExCoreData.LogTag)**** failure")
            case .success(let context):
                ExLog.log("\(ExCoreData.LogTag)**** success: \n\(self.description)")
                self.context = context
                completionHandler(context)
                return
            }
            
            completionHandler(nil)
        }
    }
    
    @discardableResult
    public class func initInstance(completionHandler: @escaping (NSManagedObjectContext?) -> Void) -> ExCoreData.Status {
        if let instance = self.getInstance() {
            ExLog.log("\(ExCoreData.LogTag)すでに\"\(self)\"のインスタンスあり -> 初期化不要")
            if let context = instance.context {
                ExLog.log("\(ExCoreData.LogTag)\t=> すでにコンテキストも初期化済み -> Initilized")
                completionHandler(context)
                return .Initilazed
            } else {
                ExLog.log("\(ExCoreData.LogTag)\t=> まだコンテキストは初期化されていない。他のスレッドで実施中と判断。 -> Initializing")
                completionHandler(nil)
                return .Initializing
            }
        } else {
            ExLog.log("\(ExCoreData.LogTag)まだインスタンスなし -> 初期化実施")
            let instance = self.init(completionHandler: completionHandler)
            self._Instance.append(instance)
            return .Initializing
        }
    }
    
    /// コンテキストを返すメソッド
    /// 注意：先にinitInstanceでcontextを初期化していないと正常な値が返ってこない。このメソッドは確実にcontextが初期化されている場合のみ利用できる
    public static func getContext() -> NSManagedObjectContext? {
        
        if let instance = self.getInstance(), let context = instance.context {
            return context
        } else {
            ExLog.error("\(ExCoreData.LogTag)まだ初期化されていません。先にinitInstanceが呼ばれて初期化される必要があります")
            return nil
        }
    }
    
    @available(OSX 10.11, *)
    public static func deleteStore(completed: @escaping () -> Void) {
        guard let instance = self.getInstance() else {
            fatalError()
        }
        self._Instance.removeAll(where: {$0.context == instance.context})
        ExCoreData.createInstance(requiredData: instance.data) { (result: ExCoreDataResult<CoreDataHelper, Error>) in
            switch result {
            case .failure:
                ExLog.log("\(ExCoreData.LogTag)Fail to get CoreDateSet instance.")
                fatalError()
            case .success(let set):
                ExLog.log("\(ExCoreData.LogTag)Success to get CoreDateSet instance.")
                set.deleteStore()
            }
            completed()
        }
    }
    
    /// DKCoreDataSetのインスタンスを別スレッド(userInteractive)上で作成して、初期化されたDKCoreDataSetをコールバックメソッド（メインスレッド上）の引数として取得する静的メソッド
    /// - parameter requiredData: XCDataモデル名(ex. TestTest.modのピリオドの前の部分)/パッケージ名(ex. jp.example.test1)/ストア名(ex. test.sqlite、補足：拡張子はsqliteを指定すること)
    /// - parameter didConfiguration: 初期化されたDKCoreDataSetインスタンスを含むDKResultを返すコールバック関数。Mainスレッド上での処理を保証する。
    private static func createInstance(requiredData lData: ExCoreData.RequiredData, didConfiguration:@escaping (ExCoreDataResult<NSManagedObjectContext, Error>) -> Void) {
        let performDidConfigurationOnMainForcefully = { (result: ExCoreDataResult<NSManagedObjectContext, Error>) -> Void in
            if Thread.isMainThread{
                didConfiguration(result)
                return
            }
            
            DispatchQueue.main.async {
                didConfiguration(result)
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let coreDataSet = try CoreDataHelper(requiredData: lData)
                performDidConfigurationOnMainForcefully(ExCoreDataResult.success(coreDataSet.context))
            } catch {
                performDidConfigurationOnMainForcefully(ExCoreDataResult.failure(error))
            }
        }
    }
}

private class CoreDataHelper {
    // MARK: - [変数・関数] -
    public let context: NSManagedObjectContext
    
    // MARK: [利用者が設定する定数]
    internal let requiredData: ExCoreData.RequiredData
    
    // MARK: [内部で利用する変数]
    /// Core Data store用ファイルを保存するためのフォルダーのパス
    private let applicationDocumentsDirectory: URL
    
    // MARK: [初期化処理]
    
    /// 初期化
    /// - parameter xcDataModelName: XCDataモデル名(ex. TestTest.modのピリオドの前の部分)
    /// - parameter packageName: パッケージ名(ex. jp.example.test1)
    /// - parameter storeDataName: ストア名(ex. test.sqlite、補足：拡張子はsqliteを指定すること)
    internal init(requiredData: ExCoreData.RequiredData) throws {
        // メンバ定数の初期化
        do {
            self.requiredData = requiredData
            
            self.applicationDocumentsDirectory = {
                /// Application SupportフォルダーのURLを取得して利用
                let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                let appSupportURL = urls[urls.count - 1]
                return appSupportURL.appendingPathComponent(requiredData.packageName)
            }()
            
            ExLog.log("\(ExCoreData.LogTag)Application Documents Directory: \(self.applicationDocumentsDirectory)")
            
            self.context = {
                let managedObjectModel: NSManagedObjectModel = {
                    let modelURL = Bundle.main.url(forResource: requiredData.xcDataModelName, withExtension: "momd")!
                    return NSManagedObjectModel(contentsOf: modelURL)!
                }()
                
                let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
                let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                context.persistentStoreCoordinator = coordinator
                return context
            }()
        }
        
        // applicationDocumentsDirectoryの正しさチェック
        try self.checkDirectoryStatus()
        // 永続ストアと関連づける
        try self.addPerssistentStored()
    }
    
    private func checkDirectoryStatus() throws {
        let fileManager = FileManager.default
        var failError: NSError?
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            let properties = try (self.applicationDocumentsDirectory as NSURL).resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
            if !(properties[URLResourceKey.isDirectoryKey]! as AnyObject).boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } catch {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError {
                do {
                    try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    failError = nserror
                }
            } else {
                failError = nserror
            }
        }
        
        if shouldFail || (failError != nil) {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            if failError != nil {
                dict[NSUnderlyingErrorKey] = failError
            }
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            throw error
        }
    }
    
    private func addPerssistentStored() throws {
        var coordinator: NSPersistentStoreCoordinator?
        
        coordinator = self.context.persistentStoreCoordinator
        
        let url = self.applicationDocumentsDirectory.appendingPathComponent(self.requiredData.storeDataName)
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
    }
    
    @available(OSX 10.11, *)
    public func deleteStore() {
        let url = self.applicationDocumentsDirectory.appendingPathComponent(self.requiredData.storeDataName)
        print("delete - \(url.absoluteString)")
        do {
            try self.context.persistentStoreCoordinator?.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
        } catch {
            print(error)
        }
    }
}

extension ExCoreData {
    open var description: String {
        var msg = "\t" + "CoreDataHelper:\n"
        msg = msg + "\t " + "xcDataModelName\t:" + self.data.xcDataModelName + "\n"
        msg = msg + "\t " + "packageName\t\t:" + self.data.packageName + "\n"
        msg = msg + "\t " + "storeDataName\t\t:" + self.data.storeDataName
        return msg
    }
}