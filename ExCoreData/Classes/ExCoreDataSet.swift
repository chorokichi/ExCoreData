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
    public typealias RequiredData = (xcDataModelName: String, packageName: String, storeDataName: String)
    public enum Status {
        case NotInitilazed
        case Initializing
        case Initilazed
    }
    
    ///
    /// 子クラスで必ず実装する必要がある変数
    ///
    open var data: ExCoreData.RequiredData {
        ExLog.error("Not Defined in Sub class")
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
        ExLog.log("Not found any instances related with \"\(self)\". The number of _Instance is \(_Instance.count)")
        return nil
    }
    
    public static func getCoreDataNum() -> Int {
        return self._Instance.count
    }
    
    var context: NSManagedObjectContext?
    
    /// このメソッドは呼び出してはいけない！！！！
    /// 補足：本当はprivateにしたいがinitInstanceメソッドで初期化する際にpublicにしておく必要がある()
    public required init(completionHandler: @escaping (NSManagedObjectContext?) -> Void) {
        ExLog.log("初期化") //ExLog.log("初期化 - " + ExFile.getFolderPathHavingCoreDataFile())
        ExCoreDataSet.factoryInstance(requiredData: self.data) { (result: ExCoreDataResult<ExCoreDataSet, Error>) in
            ExLog.log("**** callback method")
            switch result {
            case .failure:
                ExLog.log("**** failure")
            case .success(let set):
                ExLog.log("**** success: \n\(set.description)")
                self.context = set.context
                completionHandler(set.context)
                return
            }
            
            completionHandler(nil)
        }
    }
    
    @discardableResult
    public class func initInstance(completionHandler: @escaping (NSManagedObjectContext?) -> Void) -> ExCoreData.Status {
        if let instance = self.getInstance() {
            ExLog.log("すでにインスタンスあり -> 初期化不要")
            if let context = instance.context {
                ExLog.log("\tすでにコンテキストもあり -> Initilized")
                completionHandler(context)
                return .Initilazed
            } else {
                ExLog.log("\tまだコンテキストはなし -> Initializing")
                completionHandler(nil)
                return .Initializing
            }
        } else {
            ExLog.log("まだインスタンスなし -> 初期化実施")
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
            ExLog.error("まだ初期化されていません。先にinitInstanceが呼ばれて初期化される必要があります")
            return nil
        }
    }
    
//    /// Save changes in the application's managed object context before the application terminates.
//    public static func saveAnyChangesBeforeApplicationTerminates(_ sender: NSApplication, context: NSManagedObjectContext?, runClass: NSObject) -> NSApplication.TerminateReply {
//        
//        guard let context = context else {
//            ExLog.error()
//            return .terminateNow
//        }
//        
//        if !context.commitEditing() {
//            NSLog("\(NSStringFromClass(type(of: runClass.self))) unable to commit editing to terminate")
//            return .terminateCancel
//        }
//        
//        if !context.hasChanges {
//            return .terminateNow
//        }
//        
//        do {
//            try context.save()
//        } catch {
//            let nserror = error as NSError
//            // Customize this code block to include application-specific recovery steps.
//            let result = sender.presentError(nserror)
//            if result {
//                return .terminateCancel
//            }
//            
//            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
//            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info")
//            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
//            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
//            let alert = NSAlert()
//            alert.messageText = question
//            alert.informativeText = info
//            alert.addButton(withTitle: quitButton)
//            alert.addButton(withTitle: cancelButton)
//            
//            let answer = alert.runModal()
//            if answer == NSApplication.ModalResponse.alertSecondButtonReturn {
//                return .terminateCancel
//            }
//        }
//        // If we got here, it is time to quit.
//        return .terminateNow
//    }
    
    @available(OSX 10.11, *)
    public static func deleteStore(completed: @escaping () -> Void) {
        guard let instance = self.getInstance() else {
            fatalError()
        }
        self._Instance.removeAll(where: {$0.context == instance.context})
        ExCoreDataSet.factoryInstance(requiredData: instance.data) { (result: ExCoreDataResult<ExCoreDataSet, Error>) in
            switch result {
            case .failure:
                ExLog.log("Fail to get CoreDateSet instance.")
                fatalError()
            case .success(let set):
                ExLog.log("Success to get CoreDateSet instance.")
                set.deleteStore()
            }
            completed()
        }
        
    }
    
}

extension ExCoreDataSet {
    /// DKCoreDataSetのインスタンスを別スレッド(userInteractive)上で作成して、初期化されたDKCoreDataSetをコールバックメソッド（メインスレッド上）の引数として取得する静的メソッド
    /// - parameter requiredData: XCDataモデル名(ex. TestTest.modのピリオドの前の部分)/パッケージ名(ex. jp.example.test1)/ストア名(ex. test.sqlite、補足：拡張子はsqliteを指定すること)
    /// - parameter didConfiguration: 初期化されたDKCoreDataSetインスタンスを含むDKResultを返すコールバック関数。Mainスレッド上での処理を保証する。
    fileprivate static func factoryInstance(requiredData lData: ExCoreData.RequiredData, didConfiguration:@escaping (ExCoreDataResult<ExCoreDataSet, Error>) -> Void) {
        
        let performDidConfigurationOnMainForcefully = { (result: ExCoreDataResult<ExCoreDataSet, Error>) -> Void in
            guard !Thread.isMainThread else {
                didConfiguration(result)
                return
            }
            
            DispatchQueue.main.async {
                didConfiguration(result)
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let coreDataSet = try ExCoreDataSet(requiredData: lData)
                performDidConfigurationOnMainForcefully(ExCoreDataResult.success(coreDataSet))
            } catch {
                performDidConfigurationOnMainForcefully(ExCoreDataResult.failure(error))
            }
        }
    }
    
    open var description: String {
        var msg = "\t" + "ExCoreDataSet:\n"
        msg = msg + "\t " + "xcDataModelName\t:" + self.requiredData.xcDataModelName + "\n"
        msg = msg + "\t " + "packageName\t\t:" + self.requiredData.packageName + "\n"
        msg = msg + "\t " + "storeDataName\t\t:" + self.requiredData.storeDataName
        return msg
    }
}

private class ExCoreDataSet {
    // MARK: - [変数・関数] -
    public let context: NSManagedObjectContext
    
    // MARK: [利用者が設定する定数]
    internal let requiredData: ExCoreData.RequiredData
    
    // MARK: [内部で利用する変数]
    private let applicationDocumentsDirectory: URL
    
    // MARK: [初期化処理]
    
    ////// 初期化
    /// - parameter xcDataModelName: XCDataモデル名(ex. TestTest.modのピリオドの前の部分)
    /// - parameter packageName: パッケージ名(ex. jp.example.test1)
    /// - parameter storeDataName: ストア名(ex. test.sqlite、補足：拡張子はsqliteを指定すること)
    internal init(requiredData: ExCoreData.RequiredData) throws {
        // メンバ定数の初期化
        do {
            self.requiredData = requiredData
            
            self.applicationDocumentsDirectory = {
                let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                let appSupportURL = urls[urls.count - 1]
                return appSupportURL.appendingPathComponent(requiredData.packageName)
            }()
            
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
