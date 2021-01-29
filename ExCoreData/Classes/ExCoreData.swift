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
    
    deinit {
        ExLog.log("\(ExCoreData.LogTag) deinit...")
    }
    
    public typealias RequiredData = (xcDataModelName: String, packageName: String, storeDataName: String, bundle: Bundle)
    
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
        // self._InstanceにはinitInstanceを呼ぶと必ず代入され、その後初期化処理でエラーが発生すると削除する仕組みとなっている
        // 初期化中のものをカウントしないようにfilterでstoreをもたないinstanceを除外している
        return self._Instance.filter{$0.store != nil}.count
    }
    
    private var store: CoreDataStore? = nil
    
    /// ⚠️⚠️⚠️このメソッドは直接呼び出してはいけない！！！！⚠️⚠️⚠️
    ///
    /// [publicにしている理由]
    /// - 本当はprivateにしたいがinitInstanceメソッドで初期化する際に下記理由でpublic requiredにしておく必要がある
    /// - initをメタタイプから呼べるようにするためにはrequiredが必要
    /// - requiredをつけたinitは子クラスから呼ばれる可能性があるのでpublicにする必要がある
    public required init(completionHandler: @escaping (ExCoreDataInitStatus<NSManagedObjectContext, Error>) -> Void) {
        ExLog.log("\(ExCoreData.LogTag)\"\(self)\"の初期化処理開始...")
        self.createInstance() { (result: ExCoreDataResult<CoreDataStore, Error>) in
            ExLog.log("\(ExCoreData.LogTag)**** callback method")
            switch result {
            case .failure(let error):
                ExLog.error("\(ExCoreData.LogTag)**** failure")
                completionHandler(.failure(error))
            case .success(let store):
                ExLog.log("\(ExCoreData.LogTag)**** success: \n\(self.description)")
                self.store = store
                completionHandler(.success(store.context))
            }
        }
    }
    

    /// https://www.wantedly.com/companies/Supership/post_articles/57547
    private static let sem = DispatchSemaphore(value: 1)
    
    /// initInstanceを複数のスレッドから呼ぶことを許容しない(UIスレッドである必要はない)。
    public static func initInstance(completionHandler: @escaping (ExCoreDataInitStatus<NSManagedObjectContext, Error>) -> Void) {
        guard Thread.isMainThread else{
            ExLog.fatalError("このメソッドは必ずメインスレッド上で実行する必要がある。")
            DispatchQueue.main.async {
                completionHandler(.failure(NSError(domain: "ExCoreDataInitError", code: 1, userInfo: ["Description": "このメソッドは必ずメインスレッド上で実行する必要がある。"])))
            }
            return
        }
        
        defer { sem.signal() }
        sem.wait()
        if let instance = self.getInstance() {
            ExLog.log("\(ExCoreData.LogTag)すでに\"\(self)\"のインスタンスあり -> 初期化不要")
            if instance.store != nil {
                ExLog.log("\(ExCoreData.LogTag)\t=> すでにコンテキストも初期化済み -> Initilized")
                completionHandler(.initialized)
            } else {
                ExLog.log("\(ExCoreData.LogTag)\t=> まだコンテキストは初期化されていない。他のスレッドで実施中と判断。 -> Initializing")
                completionHandler(.initializing)
            }
        } else {
            ExLog.log("\(ExCoreData.LogTag)まだインスタンスなし -> 初期化開始")
            let instance = self.init { (status: ExCoreDataInitStatus<NSManagedObjectContext, Error>) in
                switch status{
                case .failure(_):
                    ExLog.log("\(ExCoreData.LogTag)\t=> 初期化失敗")
                    for instance in ExCoreData._Instance where self == type(of: instance){
                        ExCoreData._Instance.removeAll(where: {type(of: $0) == type(of: instance)})
                    }
                case .success(_):
                    ExLog.log("\(ExCoreData.LogTag)\t=> 初期化成功")
                default:
                    break
                }
                
                completionHandler(status)
            }
            
            // 初期化の成功失敗に関わらず._Instanceに保存する。
            // 初期化中にinitInstanceが再度呼ばれると並行して処理が走ってしまうため
            ExLog.log("\(ExCoreData.LogTag)_Instanceとして保存中...")
            ExCoreData._Instance.append(instance)
            ExLog.log("\(ExCoreData.LogTag)_Instanceとして保存完了！")
        }
    }
    
    /// コンテキストを返すメソッド
    /// 注意：先にinitInstanceでcontextを初期化していないと正常な値が返ってこない。このメソッドは確実にcontextが初期化されている場合のみ利用できる
    public static func getContext() -> NSManagedObjectContext? {
        guard Thread.isMainThread else{
            ExLog.fatalError("このメソッドは必ずメインスレッド上で実行する必要がある。")
            return nil
        }
        
        if let instance = self.getInstance(), let context = instance.store?.context {
            return context
        } else {
            ExLog.error("\(ExCoreData.LogTag)まだ初期化されていません。先にinitInstanceが呼ばれて初期化される必要があります")
            return nil
        }
    }
    
    /// キャッシュとして保存しているInstaneを削除する
    public static func discardStore(){
        guard let instance = self.getInstance() else {
            fatalError()
        }
        guard let context = instance.store?.context else {
            fatalError()
        }
        self._Instance.removeAll(where: {$0.store?.context == context})
    }
    
    @available(OSX 10.11, *)
    /// このクラスに関係するDBのファイルを削除しInstanceも削除する
    public static func deleteStore(completed: @escaping () -> Void) {
        guard Thread.isMainThread else{
            ExLog.fatalError("このメソッドは必ずメインスレッド上で実行する必要がある。")
            return
        }
        
        guard let instance = self.getInstance() else {
            fatalError()
        }
        
        if instance.deleteStore(){
            guard let context = instance.store?.context else {
                fatalError()
            }
            self._Instance.removeAll(where: {$0.store?.context == context})
        }
        
        completed()
    }
    
    /// DBのファイルを削除する
    private func deleteStore() -> Bool{
        guard Thread.isMainThread else{
            ExLog.fatalError("このメソッドは必ずメインスレッド上で実行する必要がある。")
            return false
        }
        
        guard let store = self.store else{
            fatalError()
        }
        
        let url = store.applicationDocumentsDirectory.appendingPathComponent(self.data.storeDataName)
        ExLog.important("\(ExCoreData.LogTag)Delete - \(url.absoluteString)")
        do {
            try store.context.persistentStoreCoordinator?.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
            return true
        } catch {
            ExLog.error("\(ExCoreData.LogTag)PersistentStore削除中にエラー発生... \(error)")
        }
        return false
    }
    
    /// DKCoreDataSetのインスタンスを別スレッド(userInteractive)上で作成して、初期化されたDKCoreDataSetをコールバックメソッド（メインスレッド上）の引数として取得する静的メソッド
    /// - parameter requiredData: XCDataモデル名(ex. TestTest.modのピリオドの前の部分)/パッケージ名(ex. jp.example.test1)/ストア名(ex. test.sqlite、補足：拡張子はsqliteを指定すること)
    /// - parameter didConfiguration: 初期化されたDKCoreDataSetインスタンスを含むDKResultを返すコールバック関数。Mainスレッド上での処理を保証する。
    private func createInstance(
        completionHandler:@escaping (ExCoreDataResult<CoreDataStore, Error>) -> Void) {
        let performDidConfigurationOnMainForcefully = { (result: ExCoreDataResult<CoreDataStore, Error>) -> Void in
            if Thread.isMainThread{
                completionHandler(result)
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let store = try CoreDataStore(requiredData: self.data)
                performDidConfigurationOnMainForcefully(ExCoreDataResult.success(store))
            } catch {
                performDidConfigurationOnMainForcefully(ExCoreDataResult.failure(error))
            }
        }
    }
}

extension ExCoreData {
    open var description: String {
        var msg = ""
        msg = msg + "\t " + "xcDataModelName\t:" + self.data.xcDataModelName + "\n"
        msg = msg + "\t " + "packageName\t\t:" + self.data.packageName + "\n"
        msg = msg + "\t " + "storeDataName\t\t:" + self.data.storeDataName
        return msg
    }
}

private class CoreDataStore {
    // MARK: - [変数・関数] -
    let context: NSManagedObjectContext
    
    // MARK: [利用者が設定する定数]
    let requiredData: ExCoreData.RequiredData
    
    // MARK: [内部で利用する変数]
    /// Core Data store用ファイルを保存するためのフォルダーのパス
    let applicationDocumentsDirectory: URL
    
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
                    ExLog.log(requiredData.bundle)
                    ExLog.log("requiredData.xcDataModelName: \(requiredData.xcDataModelName)")
                    guard let modelURL = requiredData.bundle.url(forResource: requiredData.xcDataModelName, withExtension: "momd") else{
                        fatalError()
                    }
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
}
