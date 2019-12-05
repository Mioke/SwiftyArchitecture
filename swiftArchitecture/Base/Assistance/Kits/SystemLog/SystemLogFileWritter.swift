//
//  SystemLogFileWriter.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 3/7/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit

/// Utility of writing log
internal class SystemLogFileWritter: NSObject {

    fileprivate let formatter = DateFormatter()
    fileprivate var fileName: String = ""
    fileprivate var folderPath: String = ""
    
    override init() {
        super.init()
        
        self.formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.fileName = self.formatter.string(from: Date())
        self.folderPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "SystemLog"
        
        if !FileManager.default.fileExists(atPath: self.folderPath) {
            do {
                try FileManager.default.createDirectory(atPath: self.folderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Log.println("Create System Log folder failed")
            }
        }
    }
    
    func writeText(_ text: String) -> Void {
        
        DispatchQueue.global(qos: .default).async {
            
            let content = "\(self.formatter.string(from: Date())): \n--------------\n\(text)\n--------------\n\n"
            Log.println(content)
            
            if !FileManager.default.fileExists(atPath: self.filePath()) {
                do {
                    try content.write(toFile: self.filePath(), atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    Log.println("System log write to file fialed with error: \(error)")
                }
                return
            }
            
            if let fileHandle = FileHandle(forWritingAtPath: self.filePath()),
                let data = content.data(using: String.Encoding.utf8) {

                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
    
    func allLogFiles() -> [String]? {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: self.folderPath)
        } catch {
            Log.println("System log get all files error: \(error)")
            return nil
        }
    }
    
    func textOfFile(_ fileName: String) -> String? {
        
        if let data = FileManager.default.contents(atPath: "\(self.folderPath)/\(fileName)") {
            return String(data: data, encoding: String.Encoding.utf8)
        }
        return nil
    }

    fileprivate func filePath() -> String {
        return self.folderPath + "/" + self.fileName
    }
}
