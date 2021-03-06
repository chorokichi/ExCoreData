//
//  DKRecords.swift
//  DKLibrary
//
//  Created by yuya on 2017/06/18.
//  Copyright © 2017年 yuya. All rights reserved.
//

import CoreData
import ExLog

/// カスタムNSManagedObject。
/// フェッチや作成(空)、削除の静的メソッドが利用可能。
///
/// 利用する上で制約
/// - このクラスを直接使用せずに、このクラスを継承したクラスを利用すること
/// - 子クラス名とEntity名は必ず同じにしないと動作しない。
///
/// 他にも次の二つのコンピュート変数を子クラスでオーバーライドすれば次のような使い方ができる
/// 1. PrimaryAttribute: fetchOneRecordで主キーでの一件だけの検索が可能。createEmptyEntityでvalueOfPrimaryAttributeに主キーの値をセットすれば、既存データの場合は新規作成ではなく、その既存データを取得し返す。
/// 2. MandatoryAttributes
open class ExRecords: NSManagedObject {
    public enum Result<T: ExRecords> {
        case new(T)
        case updated(T)
        case fail(String)
        
        public func getRecord() -> T?{
            switch self {
            case .new(let record):
                return record
            case .updated(let record):
                return record
            case .fail(_):
                return nil
            }
        }
    }
    
    // MARK: - [クラス・スタティック変数・関数] -
    
    /// 主キーとしている属性名
    open class var PrimaryAttribute: String? {
        return nil
    }
    
    /// 必須の属性名
    open class var MandatoryAttributes: [String] {
        return []
    }
    
    private class var EntityName: String {
        // selfは子クラスが呼んだ場合はそのクラス名となる
        "\(self)"
    }
        
    /// 空のエンティティを作成する[永続保存されない]
    /// 注意：
    /// ・主キーで一致するデータがある場合は、そのデータを返す
    /// ・主キーで一致するデータがない場合は、新規にデータを作成して主キーの値のみ設定する
    public static func createEmptyEntity<T: ExRecords>(_ context: NSManagedObjectContext, valueOfPrimaryAttribute value: String? = nil, type: T.Type) -> ExRecords.Result<T> {
        // 主キーで一致するデータがある場合は、そのデータを返す
        
        if let value = value {
            guard let AttrName = T.PrimaryAttribute else {
                fatalError("主キーの設定が子クラスでされていないにもかからず主キーの値(\(value))で検索しようとしている。")
            }
            
            if let record: T = T.fetchOneRecord(context, valueOfPrimaryAttribute: value, type: type) {
                return .updated(record)
            } else {
                guard let record: T = NSEntityDescription.insertNewObject(forEntityName: T.EntityName, into: context) as? T else {
                    fatalError("record should not be nil.")
                }
                record.setValue(value, forKey: AttrName)
                return .new(record)
            }
        } else {
            if let AttrName = T.PrimaryAttribute {
                fatalError("主キー(\(AttrName))の設定が子クラスでされているにもかからず主キーの値が設定されていない。")
            }
        }
        
        guard let record: T = NSEntityDescription.insertNewObject(forEntityName: T.EntityName, into: context) as? T else {
            fatalError("record should not be nil.")
        }
        return .new(record)
    }
    
    @nonobjc open class func fetchRequest<T: ExRecords>() -> NSFetchRequest<T> {
        return NSFetchRequest<T>(entityName: self.EntityName)
    }
    
    /// typeを引数に設定しないと宣言時に明示的にDKRecordsのサブクラスを設定する必要があり、実行時エラーの原因になる。そのため、typeをメソッド呼び出し時に強制することでそのエラーを抑えることを狙っている。
    @available(*, deprecated, message: "This will be removed in near future. Please use ExRecordHandler instead of this.")
    public static func fetchRecords<T: ExRecords>(_ context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor] = [], predicate: NSPredicate? = nil, type: T.Type) throws -> [T] {
        return try ExRecordHandler<T>().fetchRecords(context, sortDescriptors: sortDescriptors, predicate: predicate)
    }
    
    /// typeを引数に設定しないと宣言時に明示的にDKRecordsのサブクラスを設定する必要があり、実行時エラーの原因になる。そのため、typeをメソッド呼び出し時に強制することでそのエラーを抑えることを狙っている。
    @available(*, deprecated, message: "This will be removed in near future. Please use ExRecordHandler instead of this.")
    public static func fetchOneRecord<T: ExRecords>(_ context: NSManagedObjectContext, valueOfPrimaryAttribute value: String, type: T.Type) -> T? {
        return ExRecordHandler<T>().fetchOneRecord(context, valueOfPrimaryAttribute: value)
    }
    
    /// すべてのレコードを削除する[永続はされない]
    public static func deleteAllRecords(_ context: NSManagedObjectContext) throws {
        let entityDiscription = NSEntityDescription.entity(forEntityName: self.EntityName, in: context)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = entityDiscription
        if let results = try context.fetch(fetchRequest) as? [ExRecords] {
            for result in results {
                context.delete(result)
            }
        }
    }
    
    // MARK: - [メンバ関数] -
    /// 削除(永続保存されない)
    open func delete() {
        if let context = self.managedObjectContext {
            context.delete(self)
        }
    }
    
    /// 保存（永続化処理）
    /// 注意：関連するコンテキストの変更点が全て保存される。
    open func save() throws -> Bool {
        return try ExRecordUtil.saveContext(self.managedObjectContext)
    }
}
