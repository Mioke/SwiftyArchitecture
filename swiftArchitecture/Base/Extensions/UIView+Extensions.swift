//
//  UIView+Extensions.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 5/12/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    var x: CGFloat {
        set {
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
        get {
            return frame.origin.x
        }
    }
    
    var y: CGFloat {
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
        get {
            return frame.origin.y
        }
    }
    
    var height: CGFloat {
        get {
            return frame.size.height
        }
        set {
            var f = frame
            f.size.height = newValue
            frame = f
        }
    }
    
    var width: CGFloat {
        get {
            return frame.size.width
        }
        set {
            var f = frame
            f.size.width = newValue
            frame = f
        }
    }
}

@available(iOS 2.0, *)
public func CGRectGetCenter(rect: CGRect) -> CGPoint {
    return CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMidY(rect))
}