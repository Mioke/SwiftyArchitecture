//
//  LogInterface.swift
//  Alamofire
//
//  Created by KelanJiang on 2022/6/7.
//

import Foundation
import os

public enum LogLevel {
    case error, info, verbose, debug
}

public class KitLogger {
    public static let instance: KitLogger = .init()
    private init() {}
    
    public typealias Event = (level: LogLevel, message: String, file: String, line: Int)
    
    public var events: ((Event) -> Void)?
    
    public static func log(level: LogLevel, message: String, file: String = #file, line: Int = #line) {
        if let events = instance.events {
            events((level: level, message: message, file: file, line: line))
        } else {
            NSLog("[\(level.tag())] \(URL(fileURLWithPath: file).lastPathComponent):\(line) ~> \(message)")
        }
    }
}

private extension LogLevel {
    func tag() -> String {
        switch self {
        case .debug:
            return "💉"
        case .info:
            return "📄"
        case .verbose:
            return "🛰"
        case .error:
            return "🧯"
        }
    }
}

public extension KitLogger {
    static func debug(_ message: String = #function, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }
    
    static func info(_ message: String = #function, file: String = #file, line: Int = #line) {
        log(level: .info, message: message, file: file, line: line)
    }
    
    static func verbose(_ message: String = #function, file: String = #file, line: Int = #line) {
        log(level: .verbose, message: message, file: file, line: line)
    }
    
    static func error(_ message: String = #function, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, file: file, line: line)
    }
}
