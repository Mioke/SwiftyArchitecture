//
//  Path.swift
//  FileMail
//
//  Created by yizhong zhuang on 2017/5/15.
//  Copyright © 2017年 xlvip. All rights reserved.
//

import UIKit
import Foundation

class Path: NSObject {
    static var homePath: String {
        return NSHomeDirectory()
    }
    
    static var tempPath: String {
        return NSTemporaryDirectory()
    }
    
    static var docPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths.first ?? NSHomeDirectory() + "/Documents"
    }
    
    static var appPath: String {
        return Bundle.main.bundlePath
    }
    
    static var libPath: String? {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        return paths.first
        
    }
    
    static var cachePath: String? {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return paths.first
        
    }
    
    
    // 创建目录，如果已存在则返回true，不存在创建目录成功返回true，失败返回false
    static func createDirIfNeeded(at dirPath: URL) -> Bool {
        var isDir = ObjCBool(false)
        let exist = FileManager.default.fileExists(atPath: dirPath.absoluteString, isDirectory: &isDir)
        if exist && isDir.boolValue { // dir exists
            return true
        }
        do {
            try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            debugPrint("create file dir error:\(error.localizedDescription), url:\(dirPath)")
            return false
        }
        
        return true
    }
    
    static func copyFilesFile(from url: String, to dir: String) throws -> Void {
        var err: NSError? = nil
        copyFilesFile(url: URL(fileURLWithPath: url), toDir: dir) { (error) in
            err = error as NSError?
        }
        if let error = err {
            throw error
        }
    }
        
    fileprivate static func copyFilesFile(url: URL, toDir: String, completion: (Error?) -> Void) -> Void {
        var error: NSError?
        let fileCoordinator = NSFileCoordinator.init()
        if url.startAccessingSecurityScopedResource() {
            url.stopAccessingSecurityScopedResource()
            return
        }
        fileCoordinator.coordinate(
            readingItemAt: url,
            options: .withoutChanges,
            error: &error,
            byAccessor: { (url) in
                debugPrint("待拷贝文件：\(url.absoluteString)")
                let toUrl = URL.init(fileURLWithPath: toDir.appending("/\(url.lastPathComponent)"))
                do {
                    try FileManager.default.copyItem(at: url, to: toUrl)
                    completion(nil)
                } catch let error {
                    debugPrint("拷贝文件失败：\(error)")
                    completion(error)
                }
                debugPrint("stopAccessingSecurityScopedResource:\(url.stopAccessingSecurityScopedResource())")
        })
        if let err = error {
            debugPrint("拷贝files中文件出错：\(err)")
            debugPrint("stopAccessingSecurityScopedResource:\(url.stopAccessingSecurityScopedResource())")
            completion(err)
        }
    }
}

