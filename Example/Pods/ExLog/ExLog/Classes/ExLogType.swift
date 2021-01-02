//
//  ExLogType.swift
//  ExLog
//
//  Created by yuya on 2018/08/05.
//

import Foundation

// - MARK: - ログの種類(頭につけるタグ)
public enum ExLogType : String{
    case Info = ""
    case Important = "[Important]"
    case Debug = "[DEBUG]"
    case Error = "[Error]"
    
    func getEmoji() -> String{
        //絵文字表示: command + control + スペースキー
        switch self{
        case .Info:
            return "🗣"
        case .Important:
            return "📍"
        case .Debug:
            return "✂️"
        case .Error:
            return "⚠️"
            
        }
    }
}
