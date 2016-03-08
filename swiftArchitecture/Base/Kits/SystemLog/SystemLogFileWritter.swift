//
//  SystemLogFileWriter.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 3/7/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit

class SystemLogFileWritter: NSObject {

    private let formatter = NSDateFormatter()
    private var fileName: String!
    private var folderPath: String!
    
    override init() {
        super.init()
        
        self.formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.fileName = self.formatter.stringFromDate(NSDate())
        self.folderPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first! + "SystemLog"
        
        if !NSFileManager.defaultManager().fileExistsAtPath(self.folderPath) {

            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(self.folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.debugPrintln("Create System Log folder failed")
            }
        }
    }
    
    func writeText(text: String) -> Void {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
            
            let content = "\(self.formatter.stringFromDate(NSDate())): \n--------------\n\(text)\n--------------\n\n"
            
            if !NSFileManager.defaultManager().fileExistsAtPath(self.filePath()) {
                do {
                    try content.writeToFile(self.filePath(), atomically: true, encoding: NSUTF8StringEncoding)
                } catch {
                    Log.debugPrintln("System log write to file fialed with error: \(error)")
                }
                return
            }
            
            if let fileHandle = NSFileHandle(forWritingAtPath: self.filePath()), data = content.dataUsingEncoding(NSUTF8StringEncoding) {

                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }
        }
    }
    
    func allLogFiles() -> [String]? {
        do {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtPath(self.folderPath)
        } catch {
            Log.debugPrintln("System log get all files error: \(error)")
            return nil
        }
    }
    
    func textOfFile(fileName: String) -> String? {
        
        if let data = NSFileManager.defaultManager().contentsAtPath("\(self.folderPath)/\(fileName)") {
            return String(data: data, encoding: NSUTF8StringEncoding)
        }
        return nil
    }

    private func filePath() -> String {
        return self.folderPath + "/" + self.fileName
    }
}