//
//  DKRecordsUtil.swift
//  DKLibrary
//
//  Created by yuya on 2017/06/18.
//  Copyright © 2017年 yuya. All rights reserved.
//

import CoreData
import ExLog

public struct ExRecordUtil {
    /// コンテキストの変更点を保存するための関数。変更なければfalseを返す。
    /// - parameter context: コンテキスト
    /// - returns: 変更の保存に成功した場合true。変更が一件もなければfalseを返す。
    /// - throws: 変更点があるのに永続化に失敗した場合のエラー
    public static func saveContext (_ context: NSManagedObjectContext?) throws -> Bool {
        
        guard let context = context else {
            ExLog.error("context is empty")
            return false
        }
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                ExLog.error("Unresolved error \(nserror), \(nserror.userInfo)")
                throw nserror
            }
            return true
        }
         
        ExLog.log("Context does not have any changes")
        return false
    }
}
