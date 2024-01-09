//
//  SATextView.swift
//  SAD
//
//  Created by KelanJiang on 2022/12/2.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import UIKit

class SATextView: UITextView {
  
  /*
   // Only override draw() if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   override func draw(_ rect: CGRect) {
   // Drawing code
   }
   */
  enum EditType {
    case plain
    case code
  }
  
  var editType: EditType = .plain {
    didSet { editTypeDidChanged() }
  }
  
  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  func editTypeDidChanged() {
    switch editType {
    case .code:
      let style = NSMutableParagraphStyle()
      //            style.paragraphSpacing = 16
      //            style.paragraphSpacingBefore = 16
      
      self.typingAttributes = [
        .SACodeBlock: true,
        .backgroundColor: UIColor.systemGroupedBackground,
        .paragraphStyle: style
      ]
    case .plain:
      self.typingAttributes = [:]
    }
  }
}

extension NSAttributedString.Key {
  static let SACodeBlock = NSAttributedString.Key.init(rawValue: "SACodeBlock")
}
