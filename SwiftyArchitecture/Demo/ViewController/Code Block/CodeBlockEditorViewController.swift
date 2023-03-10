import UIKit
import SnapKit
import Combine

class CodeBlockEditorViewController: UIViewController {
  
  var textView: SATextView = buildTextView()
  @IBOutlet weak var codeEnableSwitch: UISwitch!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.addSubview(textView)
    view.sendSubviewToBack(textView)
    textView.snp.makeConstraints { make in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }
    
    textView.delegate = self
    textView.editType = .code
    
    textView.layoutManager.delegate = self
    
    codeEnableSwitch.addTarget(self, action: #selector(codeSwitchDidChange), for: .valueChanged)
  }
  
  static func buildTextView() -> SATextView {
    let storage = NSTextStorage()
    
    let container = SATextContainer(size: .zero)
    container.widthTracksTextView = true
    container.heightTracksTextView = true
    
    let layoutManager = SALayoutManager()
    storage.addLayoutManager(layoutManager)
    layoutManager.addTextContainer(container)
    
    return SATextView(frame: .zero, textContainer: container)
  }
  
  @objc
  func codeSwitchDidChange() {
    textView.editType = codeEnableSwitch.isOn ? .code : .plain
  }
}

extension CodeBlockEditorViewController: UITextViewDelegate {
  
  func textViewDidChange(_ textView: UITextView) {
    //        print(textView.textContainer, textView.textContainer.layoutManager, textView.textContainer.layoutManager?.textContainers)
    
  }
}

extension CodeBlockEditorViewController: NSLayoutManagerDelegate {
  
//  func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
//    let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
//    print("#1", "g:\(glyphIndex)", "c:\(charIndex)", rect)
//
//    if let theString = layoutManager.textStorage?.string {
//      let theChar = theString[theString.index(theString.startIndex, offsetBy: charIndex)]
//      print("#2 the char: \(theChar)")
//    }
//
//    guard let storage = layoutManager.textStorage, storage.length > charIndex + 1 else { return 0.5 }
//
//    let preAttribute = storage.attribute(.SACodeBlock, at: charIndex, effectiveRange: nil)
//    let afterAttribute = storage.attribute(.SACodeBlock, at: charIndex + 1, effectiveRange: nil)
//
//    if preAttribute == nil, afterAttribute != nil {
//      return 20
//    }
//
//    return 0.5
//  }
  
  func layoutManager(_ layoutManager: NSLayoutManager, paragraphSpacingBeforeGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
    let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
    print("#1", "g:\(glyphIndex)", "c:\(charIndex)", rect)
    
    if let theString = layoutManager.textStorage?.string, layoutManager.textStorage?.length ?? 0 > charIndex {
      let theChar = theString[theString.index(theString.startIndex, offsetBy: charIndex)]
      print("#2 the char: \(theChar)")
    }
    
    guard let storage = layoutManager.textStorage, charIndex > 0 else { return 0.5 }
    
    let currentAttribute = storage.attribute(.SACodeBlock, at: charIndex, effectiveRange: nil)
    let preAttribute = storage.attribute(.SACodeBlock, at: charIndex - 1, effectiveRange: nil)
    
    if preAttribute == nil, currentAttribute != nil {
      return 20
    }
    return 0.5
  }
  
  func layoutManager(_ layoutManager: NSLayoutManager, paragraphSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
    let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
    print("#3", "g:\(glyphIndex)", "c:\(charIndex)", rect)
    
    if let theString = layoutManager.textStorage?.string, layoutManager.textStorage?.length ?? 0 > charIndex {
      let theChar = theString[theString.index(theString.startIndex, offsetBy: charIndex)]
      print("#4 the char: \(theChar)")
    }
    return 0.5
  }
  
  
}
