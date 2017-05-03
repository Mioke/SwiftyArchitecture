//
//  SystemLog.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 3/7/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit

/// Log in console and write the log in files.
public class SystemLog: NSObject {
    
    private static let instance = SystemLog()
    
    fileprivate let writter = SystemLogFileWritter()
    fileprivate var enabled: Bool = true
    
    /// Set this system enabled or not.
    ///
    /// - Parameter enable: Bool value of enabled or not.
    public class func set(enable: Bool) -> Void {
        instance.enabled = enable
        
        if enable {
            NSSetUncaughtExceptionHandler({ (exception: NSException) -> Void in
                SystemLog.write("\(exception)")
            })
        }
    }
    
    /// Log some object info
    ///
    /// - Parameter obj: Something need to log
    public class func write(_ obj: Any) -> Void {
        
        if instance.enabled {
            
            if obj is String {
                instance.writter.writeText(obj as! String)
            } else {
                let text = "\(obj)"
                instance.writter.writeText(text)
            }
        }  
    }
    
    /// Get all log files' name in sandbox
    ///
    /// - Returns: An array of files' name
    public class func allLogFiles() -> [String]? {
        return instance.writter.allLogFiles()
    }
    
    /// Get content of a file
    ///
    /// - Parameter fileName: file name, **not path**.
    /// - Returns: Content of giving file, `nil` when file doesn't exists.
    public class func contentsOfFile(_ fileName: String) -> String? {
        return instance.writter.textOfFile(fileName)
    }
    
    /// Try to present a view controller that listed all log files.
    public class func activeDevelopUI() {
        let nav = UINavigationController(rootViewController: SystemLogFilesBrowser())
        UIApplication.shared.windows.first?.rootViewController?.present(nav, animated: true, completion: nil)
    }
}

