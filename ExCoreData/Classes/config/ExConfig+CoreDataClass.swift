//
//  ExConfig+CoreDataClass.swift
//  ExCoreData
//
//  Created by yuya on 2021/01/24.
//
//

import CoreData
import ExLog


@objc(ExConfig)
open class ExConfig: ExRecords{
    struct Params {
        static let Key = "key"
    }
    
    /// 主キーとしている属性名
    override public class var PrimaryAttribute: String? {
        return Params.Key
    }
    
    @discardableResult
    public static func upsert(key: String, val: String) -> ExConfig? {
        assert(!key.isEmpty)
        assert(Thread.isMainThread)
        let result = ExConfig.createEmptyEntity(ConfigCoreData.getContext()!, valueOfPrimaryAttribute: key, type: ExConfig.self)
        let newConfig: ExConfig?
        switch result {
        case .fail(let error):
            ExLog.error(error)
            newConfig = nil
        case .updated(let config):
            ExLog.log("Updated Config \(key) from \(config.value!) to \(val)")
            config.value = val
            newConfig = config
        case .new(let config):
            ExLog.log("Created Config \(key) / \(val)")
            config.value = val
            newConfig = config
        }
        
        return  newConfig
    }
    
    /// keyの値を取得する。存在しない場合、取得時にエラーが発生した場合はnilを返す。
    /// - Parameter key: キー
    /// - Returns: 値
    public static func get(key: String) -> String? {
        assert(Thread.isMainThread)
        do {
            return try getConfig(key: key, in: ConfigCoreData.getContext()!)?.value
        } catch {
            ExLog.error(error)
            return nil
        }
    }
    
    // keyの値を取得する。存在しない場合、nilを返す。
    /// - Parameter key: キー
    /// - Returns: 値
    /// - Throws: NSManagedObjectContect#fetch呼び出し時のエラー
    public static func getStrictly(key: String) throws -> String? {
        assert(Thread.isMainThread)
        return try getConfig(key: key, in: ConfigCoreData.getContext()!)?.value
    }
    
    public static func delete(key: String) {
        assert(!key.isEmpty)
        assert(Thread.isMainThread)
        let context = ConfigCoreData.getContext()!
        do{
            if let config = try getConfig(key: key, in: context) {
                config.delete()
            }else{
                ExLog.error("Not found any value of this key(\(key)).")
            }
        }catch{
            ExLog.error(error)
        }
    }
    
    private static func getConfig(key: String, in context: NSManagedObjectContext) throws -> ExConfig? {
        let predicate = NSPredicate(format: "\(Params.Key) = %@", key)
        let configs = try ExRecordHandler<ExConfig>().fetchRecords(context, predicate: predicate)
        if configs.count == 1 {
            return configs[0]
        } else if configs.count > 1{
            ExLog.error("There should not be greater than or equal to 2 configs with one key.[key: \(key)]")
            return configs[0]
        } else {
            return nil
        }
    }
}
