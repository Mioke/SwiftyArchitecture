//
//  UIRelevance.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/30.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

/// UI相关类，可以用extension添加App UI属性
final public class UI {
    /* 缓存相关属性，减少调用方法的次数 */
    fileprivate static let screenHeight: CGFloat = UIScreen.main.bounds.size.height
    fileprivate static let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    
    public class var SCREEN_HEIGHT: CGFloat {
        get {
            return screenHeight
        }
    }
    public class var SCREEN_WIDTH: CGFloat {
        get {
            return screenWidth
        }
    }
    /// For changing the default font.
    public static var _defaultFont: UIFont = UIFont.systemFont(ofSize: 12)
    /**
     Default font of application
     
     - parameter size: Size of the font
     */
    public class func defaultFont(ofSize size: CGFloat) -> UIFont {
        return self._defaultFont.withSize(size)
    }
}


public protocol ReusableView { }
public protocol NibLoadableView: AnyObject { }

extension ReusableView where Self: UITableViewCell {
    public static var reusedIdentifier: String {
        return String(describing: self.self)
    }
}

extension NibLoadableView where Self: UIView {
    public static var NibName: String {
        return String(describing: self.self)
    }
}

extension UITableView {
    public func registerNib<T: UITableViewCell>(_: T.Type) -> Void where T: ReusableView, T: NibLoadableView {
        let nib = UINib(nibName: T.NibName, bundle: nil)
        self.register(nib, forCellReuseIdentifier: T.reusedIdentifier)
    }
    public func dequeReusableCell<T: UITableViewCell>(forIndexPath ip: IndexPath) -> T where T: ReusableView {
        guard let cell = self.dequeueReusableCell(withIdentifier: T.reusedIdentifier, for: ip) as? T else {
            fatalError("couldn't deque cell with identifier: \(T.reusedIdentifier)")
        }
        return cell
    }
}
