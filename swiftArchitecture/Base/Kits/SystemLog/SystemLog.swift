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
    
    private let writter = SystemLogFileWritter()
    private var enabled: Bool = true

    class func setEnable(enable: Bool) -> Void {
        
        instance.enabled = enable
        
        if enable {
            NSSetUncaughtExceptionHandler({ (exception: NSException) -> Void in
                SystemLog.write("\(exception)")
            })
        }
    }

    class func write(obj: AnyObject?) -> Void {
        
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

    class func contentsOfFile(fileName: String) -> String? {
        return instance.writter.textOfFile(fileName)
    }
    
    class func activeDevelopUI() {
        let nav = UINavigationController(rootViewController: SystemLogFilesBrowser())
        UIApplication.sharedApplication().windows.first?.rootViewController?.presentViewController(nav, animated: true, completion: nil)
    }
}

