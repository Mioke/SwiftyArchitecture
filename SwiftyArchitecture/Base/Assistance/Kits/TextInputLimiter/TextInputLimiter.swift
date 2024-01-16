//
//  TextInputLimiter.swift
//  FileMail
//
//  Created by jiangkelan on 20/05/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit

@objc public protocol Inputer: AnyObject {
}

extension UITextField: Inputer { }
extension UITextView: Inputer { }

public class InputLimiter<T: Inputer>: NSObject {
    
    public var maxCount: Int
    public var reachMaxHandler: (() -> Void)?
    public var contentDidChanged: ((String?) -> Void)?
    
    weak var inputer: T?

    public init(with inputer: T, maxCount: Int) {
        self.maxCount = maxCount
        self.inputer = inputer
        
        super.init()
    }
    
    @objc fileprivate func contentChanged() -> Void {
        guard let inputer = inputer else {
            return
        }
        if let textfield = inputer as? UITextField {
            self._inputerDidChanged(textfield)
        } else if let textView = inputer as? UITextView {
            self._inputerDidChanged(textView)
        }
    }
    
    // text field
    fileprivate func _inputerDidChanged(_ inputer: UITextField) -> Void {
        
        guard let text = inputer.text else {
            return
        }
        
        if let selected = inputer.markedTextRange,
            let _ = inputer.position(from: selected.start, offset: 0) {
            
        } else {
            if text.length > self.maxCount {
                inputer.text = text[0..<self.maxCount]
                self.reachMaxHandler?()
            }
        }
        self.contentDidChanged?(inputer.text)
    }
    
    // text view
    fileprivate func _inputerDidChanged(_ inputer: UITextView) -> Void {
        
        guard let text = inputer.text else {
            return
        }
        
        if let selected = inputer.markedTextRange,
            let _ = inputer.position(from: selected.start, offset: 0) {
            
        } else {
            if text.length > self.maxCount {
//                let rangeIndex = (text as NSString).rangeOfComposedCharacterSequence(at: self.maxCount)
//                if rangeIndex.length == 1 {
//                    inputer.text = text[0..<self.maxCount]
//                } else {
//                    let realRange = (text as NSString).rangeOfComposedCharacterSequences(for: NSMakeRange(0, self.maxCount))
//                    inputer.text = (text as NSString).substring(with: realRange)
//                }
                inputer.text = text[0..<self.maxCount]
                self.reachMaxHandler?()
            }
        }
        self.contentDidChanged?(inputer.text)
    }
}

extension InputLimiter where T: UIControl {
    public func setup() -> Void {
        inputer?.addTarget(self, action: #selector(contentChanged), for: .editingChanged)
    }
    public func unload() -> Void {
        inputer?.removeTarget(self, action: #selector(contentChanged), for: .editingChanged)
    }
}






