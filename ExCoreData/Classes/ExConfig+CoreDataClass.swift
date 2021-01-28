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
    
    public static func get(key: String) -> String? {
        assert(Thread.isMainThread)
        return getConfig(key: key, in: ConfigCoreData.getContext()!)?.value
    }
    
    public static func delete(key: String) {
        assert(!key.isEmpty)
        assert(Thread.isMainThread)
        let context = ConfigCoreData.getContext()!
        if let config = getConfig(key: key, in: context) {
            config.delete()
        }
    }
    
    private static func getConfig(key: String, in context: NSManagedObjectContext) -> ExConfig? {
        let predicate = NSPredicate(format: "\(Params.Key) = %@", key)
        do {
            let configs = try ExConfig.fetchRecords(context, predicate: predicate, type: ExConfig.self)
            if configs.count == 1 {
                return configs[0]
            } else {
                return nil
            }
        } catch {
            ExLog.error(error)
            return nil
        }
    }
}
