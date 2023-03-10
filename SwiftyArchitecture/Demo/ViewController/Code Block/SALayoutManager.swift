//
//  SALayoutManager.swift
//  SAD
//
//  Created by KelanJiang on 2022/12/5.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import UIKit

class SALayoutManager: NSLayoutManager {
    
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
//
//        guard let nsstring = self.textStorage?.string as? NSString else { return }
//        print("JKL - prepare to show range: \(glyphsToShow), \n\ttext: \(nsstring.substring(with: glyphsToShow))")
    }
    
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        
//        guard let nsstring = self.textStorage?.string as? NSString else { return }
//        print("JKL - prepare to draw background: \(glyphsToShow), \n at origin: \(origin),\n text: \(nsstring.substring(with: glyphsToShow))")
    }
    
//    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
//#if DEBUG
//        let rects = transfromArrayPointerToArray(rectArray, count: rectCount)
//        print(rects, charRange, color)
//#endif
//
//        guard let attributedString = self.textStorage?.attributedSubstring(from: charRange),
////              let isCodeBlock = attributedString.attribute(.SACodeBlock, at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: attributedString.length)) as? Bool,
//              let isCodeBlock = attributedString.attribute(.SACodeBlock, at: 0, effectiveRange: nil) as? Bool,
//              isCodeBlock
//        else {
//            super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
//            return
//        }
//
//        var codeRect = CGRect(origin: rectArray.pointee.origin,
//                              size: .init(width: UIScreen.main.bounds.width - rectArray.pointee.origin.x * 2, height: 0))
//        // find largest
//        var p = rectArray
//        (0 ..< rectCount - 1).forEach { _ in
//            p = p.pointee.maxY < p.successor().pointee.maxY ? p.successor() : p
//        }
//        codeRect.size.height = p.pointee.origin.y + p.pointee.size.height - rectArray.pointee.origin.y
//
////        let roundedRectPath = UIBezierPath(roundedRect: codeRect, cornerRadius: 8)
////        roundedRectPath.stroke()
//
//        withUnsafePointer(to: codeRect) { pointer in
//            p = pointer
//        }
//
//        super.fillBackgroundRectArray(p, count: 1, forCharacterRange: charRange, color: color)
//    }

}


func transfromArrayPointerToArray<T>(_ pointer: UnsafePointer<T>, count: Int) -> [T] {
    var p: UnsafePointer<T> = pointer
    return (0 ..< count).map { _ in
        defer { p = p.successor() }
        return p.pointee
    }
}
