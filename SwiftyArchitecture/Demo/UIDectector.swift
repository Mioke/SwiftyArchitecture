//
//  UIDectector.swift
//  EntryTaskProject
//
//  Created by KelanJiang on 2019/10/24.
//  Copyright © 2019 Shopee. All rights reserved.
//

import UIKit
import CoreFoundation

extension CFRunLoopActivity {
    var description: String {
        switch self {
        case .entry: return "kCFRunLoopEntry"
        case .beforeTimers: return "kCFRunLoopBeforeTimers"
        case .beforeSources: return "kCFRunLoopBeforeSources"
        case .beforeWaiting: return "kCFRunLoopBeforeWaiting"
        case .afterWaiting: return "kCFRunLoopAfterWaiting"
        case .exit: return "kCFRunLoopExit"
        default: return ""
        }
    }
}

open class UIDetector: NSObject {
    public static let shared = UIDetector()
    private override init() { super.init() }
    
    private let workerQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
    private let semaphore = DispatchSemaphore(value: 0)
    private var observer: CFRunLoopObserver?
    private var activity: CFRunLoopActivity?
    private var timeoutCount: Int = 0 {
        didSet {
            print("frame lose: \(timeoutCount)")
        }
    }
    
    private var lastDumpInfo: String?
    private let writeQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
    
    /// Set log function enable or not.
    public var isLogEnabled = true
    
    /// Where the log file should be saved. If this property is nil,
    /// log function won't work at all.
    public var logLocation: URL?
    
    /// Mark of the worker queue.
    public private(set) var isRunning: Bool = false
    
    /// Start monitor and receive messages.
    public func startMonitor() -> Void {
        if self.isRunning { return }
        
        observer = CFRunLoopObserverCreateWithHandler(
            nil,
            CFRunLoopActivity.allActivities.rawValue,
            true,
            0
        ) { observer, activity in
            runloopObserver(observer, activity)
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, CFRunLoopMode.commonModes)
        self.startWorkerQueue()
    }
    
    /// Stop all monitor actions and be remove from observer.
    public func stopMonitor() -> Void {
        self.isRunning = false
        if let ob = self.observer {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), ob, CFRunLoopMode.commonModes)
            self.observer = nil
        }
    }
    
    private func startWorkerQueue() -> Void {
        self.isRunning = true
        weak var ws = self
        workerQueue.async {
            guard let ss = ws else { return }
            Thread.current.name = "UIDetector"
            while ss.isRunning {
                let rtn = ss.semaphore.wait(timeout: .now() + .milliseconds(16))
                if case DispatchTimeoutResult.timedOut = rtn, let activity = ss.activity {
                    switch activity {
                    case .afterWaiting/* beginning of the process */, .beforeSources /* end of the process */:
                        ss.timeoutCount += 1
                        if let flag = LogFlag(intValue: ss.timeoutCount) {
                            ss.writeInSeaLogger(with: flag)
                        }
                    default:
                        break
                    }
                } else {
                    ss.reset()
                }
            }
        }
    }
    
    fileprivate func notifyWorker(with activity: CFRunLoopActivity) -> Void {
        print(activity.description)
        self.activity = activity
        semaphore.signal()
    }
    
    private func reset() {
        timeoutCount = 0
    }
    
    enum LogFlag: String {
        case over16ms = "[1 frame]"
        case over3frames = "[3 frames]"
        case over10frames = "[10 frames]"
        
        init?(intValue: Int) {
            switch intValue {
            case 1: self = .over16ms
            case 3: self = .over3frames
            case 10: self = .over10frames
            default: return nil
            }
        }
    }
    
    private func writeInSeaLogger(with flag: LogFlag) {
        DispatchQueue.main.async {
            print(flag.rawValue, Thread.callStackSymbols.joined(separator: "\n"))
        }
//        let info = BSBacktraceLogger.bs_backtraceOfMainThread()
//        writeQueue.async { [weak self] in
//            // 3. dispose same info
//            guard let info = info,
//                  self?.lastDumpInfo != info
//            else {
//                return
//            }
//            self?.lastDumpInfo = info
//            Logger.info(flag.rawValue + "\n" + info)
//        }
    }
    
    private func detectUIStuck() {
//        if var loc = logLocation, isLogEnabled {
//            // 1. get all stack info
//            let info = BSBacktraceLogger.bs_backtraceOfAllThread()
//            // 2. dispatch to write queue to record
//            weak var ws = self
//            writeQueue.async {
//                // 3. dispose same info
//                if let last = ws?.lastDumpInfo, last == info {
//                    return
//                }
//                // 4. save info to disk
//                guard
//                    let info = info,
//                    let contents = info.data(using: String.Encoding.utf8)
//                    else {
//                        return
//                }
//                ws?.lastDumpInfo = info
//                loc.appendPathComponent("UI_Stuck_Detector_\(Date())")
//                FileManager.default.createFile(atPath: loc.path,
//                                               contents: contents,
//                                               attributes: nil)
//            }
//        }
    }
}


func runloopObserver(_ observer: CFRunLoopObserver?, _ activity: CFRunLoopActivity) {
    UIDetector.shared.notifyWorker(with: activity)
}
