//
//  NotificationService.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 03/01/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationService: NSObject {
    
    private static let service: NotificationService = NotificationService()
    class func current() -> NotificationService {
        return NotificationService.service
    }
    
    private var requestCompletionblock: ((Bool, Error?) -> Void)?
    @available(iOS 10.0, *)
    func setRequestCompletion(block: ((Bool, Error?) -> Void)?) -> Void {
        self.requestCompletionblock = block
    }
    
    func requestAuthorization() -> Void {
        if #available(iOS 10.0, *) {
            let completion = self.requestCompletionblock ??
                { (granted: Bool, error :Error?) in
                    
            }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge],
                                                                    completionHandler: completion)
        } else {
            // Fallback on earlier versions
            let types: UIUserNotificationType = [.alert, .badge, .sound]
            
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
}
