//
//  ConfigCoreData.swift
//  ExCoreData
//
//  Created by yuya on 2021/01/24.
//

import CoreData
import ExLog

public class ConfigCoreData: ExCoreData {
    private static var packageName = "sample"
    
    /// This should be called on AppDelegate#didFinishLaunchingWithOptions.
    public static func initConfig(packageName: String, completionHandler: @escaping (ExCoreDataInitStatus<NSManagedObjectContext, Error>) -> Void){
        ConfigCoreData.packageName = packageName
        ConfigCoreData.initInstance(completionHandler: completionHandler)
    }
    
    public override var data: ExCoreData.RequiredData {
        let data = ExCoreData.RequiredData(
            "ConfigModel",
            ConfigCoreData.packageName,
            "ConfigModel",
            Bundle(for: ConfigCoreData.self))
            
        return data
    }
}
