//
//  TextInputLimiter.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 24/05/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit

class TextInputLimiter: NSObject {
    public var maxTextCount: Int
    public var reachMaxHandler: (() -> Void)?
    
    public init(withMaxCount count: Int) {
        self.maxTextCount = count
        super.init()
    }
    
    public func inputer<T: UITextField>(_ inputer: T,
                        shouldChangeCharactersIn range: NSRange,
                        replacement text: String) -> Bool {
        let current = inputer.text
        return origin(text: current, shouldChangeIn: range, replacement: text)
    }
    
    public func inputer<T: UITextView>(_ inputer: T,
                        shouldChangeCharactersIn range: NSRange,
                        replacement text: String) -> Bool {
        let current = inputer.text
        return origin(text: current, shouldChangeIn: range, replacement: text)
    }
    
    private func origin(text: String?, shouldChangeIn range: NSRange, replacement replace: String) -> Bool {
        guard let text = text else {
            return true
        }
        
        if text.length >= maxTextCount && replace.length > 0 && range.length == 0 {
            reachMaxHandler?()
            return false
        }
        return true
    }
}
