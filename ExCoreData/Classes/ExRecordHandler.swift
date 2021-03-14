//
//  ExRecordHandler.swift
//  ExCoreData
//
//  Created by yuya on 2021/03/13.
//

import Foundation
import CoreData
import ExLog

open class ExRecordHandler<R: ExRecords> {
    public init() {
    }
    
    open func fetchRecords(_ context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor] = [], predicate: NSPredicate? = nil) throws -> [R] {
        let fetchRequest: NSFetchRequest<R> = R.fetchRequest()
        if sortDescriptors.count > 0 {
            fetchRequest.sortDescriptors = sortDescriptors
        }
        
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        let records: [R] = try self.fetch(context, request: fetchRequest)
        return records
    }
    
    /// typeを引数に設定しないと宣言時に明示的にDKRecordsのサブクラスを設定する必要があり、実行時エラーの原因になる。そのため、typeをメソッド呼び出し時に強制することでそのエラーを抑えることを狙っている。
    open func fetchOneRecord(_ context: NSManagedObjectContext, valueOfPrimaryAttribute value: String) -> R? {
        guard let attr = R.PrimaryAttribute else {
            fatalError("Should not call this method when R class does not have PrimaryAttribute")
        }
        
        let predicate = NSPredicate(format: "\(attr) == %@", value)
        guard let records = try? self.fetchRecords(context, predicate: predicate) else {
            fatalError("fetchRecords中にエラー発生")
        }
        
        // 取得レコード数に応じて処理分け(2件以上はありえないはず)
        if records.count == 1 {
            return records[0]
        } else if records.count == 0 {
            return nil
        } else {
            fatalError("主キーによる検索にもかかわらず結果が\(records.count)件！！！！")
        }
    }
    
    /// # test時にオーバーラップして利用するためにopenにしている。基本はprivateとしてメソッドから利用される。
    open func fetch(_ context: NSManagedObjectContext, request: NSFetchRequest<R>) throws -> [R]{
        return try context.fetch(request)
    }
}


