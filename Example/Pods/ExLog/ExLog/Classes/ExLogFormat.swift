//
//  ExLogFormat.swift
//  ExLog
//
//  Created by yuya on 2018/08/05.
//

import Foundation

// - MARK: - ログのフォーマット（時刻の表示長・関数名）
public enum ExLogFormat{
    case Normal
    case Short
    case Raw
    
    func string(emoji:String, date:Date, msg:String, functionName:String, classDetail:String, lineNumber:Int) -> String{
        // 日時フォーマット
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let threadName = Thread.isMainThread ? "Main" : "Sub "
        
        switch self{
        case .Normal:
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            let dateStr = dateFormatter.string(from: Date())
            return "[\(threadName)][\(emoji)][\(dateStr)]:\(msg) [\(functionName)/\(classDetail)(\(lineNumber))]"
        case .Short:
            dateFormatter.dateFormat = "HH:mm:ss"
            let dateStr = dateFormatter.string(from: Date())
            return "[\(threadName)][\(emoji)][\(dateStr)]:\(msg) [\(classDetail)(\(lineNumber))]"
        case .Raw:
            return "\(msg)"
        }
    }
}
