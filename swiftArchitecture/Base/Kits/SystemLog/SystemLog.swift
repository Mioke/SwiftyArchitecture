//
//  SystemLog.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 3/7/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit

class SystemLog: NSObject {
    
    static let instance = SystemLog()
    
    fileprivate let writter = SystemLogFileWritter()
    fileprivate var enabled: Bool = true

    class func set(enable: Bool) -> Void {
        
        instance.enabled = enable
        
        if enable {
            NSSetUncaughtExceptionHandler({ (exception: NSException) -> Void in
                SystemLog.write("\(exception)")
            })
        }
    }

    class func write(_ obj: Any) -> Void {
        
        if instance.enabled {
            
            if obj is String {
                instance.writter.writeText(obj as! String)
            } else {
                let text = "\(obj)"
                instance.writter.writeText(text)
            }
        }  
    }
    
    class func allLogFiles() -> [String]? {
        return instance.writter.allLogFiles()
    }

    class func contentsOfFile(_ fileName: String) -> String? {
        return instance.writter.textOfFile(fileName)
    }
    
    class func activeDevelopUI() {
        let nav = UINavigationController(rootViewController: SystemLogFilesBrowser())
        UIApplication.shared.windows.first?.rootViewController?.present(nav, animated: true, completion: nil)
    }
}

