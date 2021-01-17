//
//  ExCoreDataInitStatus.swift
//  ExCoreData
//
//  Created by yuya on 2021/01/16.
//

import CoreData

/// ExCoreDataで初期化処理を呼び出した時に返ってくるステータス
public enum ExCoreDataInitStatus<T:NSManagedObjectContext, E:Error>  {
    case initializing
    case initialized
    case success(T)
    case failure(E)
}
