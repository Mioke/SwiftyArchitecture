//
//  SystemLogBrowser.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 3/8/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit
/// A view controller for displaying content of a log file
public class SystemLogBrowser: UIViewController {
    
    var fileName: String!

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        guard self.fileName != nil else {
            fatalError("file name must not be nil")
        }
        
        self.title = self.fileName
        self.view.backgroundColor = UIColor.white
        
        if let content = SystemLog.contentsOfFile(self.fileName) {
            
            let scrollView = UIScrollView(frame: self.view.bounds)
            self.view.addSubview(scrollView)
            
            let attributeText = NSAttributedString(string: content, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)])
            let height = attributeText.boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width - 30, height: 99999), options: .usesLineFragmentOrigin, context: nil).height
            
            let label = UILabel(frame: CGRect(x: 15, y: 15, width: UIScreen.main.bounds.size.width - 30, height: height))
            label.numberOfLines = 0
            label.attributedText = attributeText
            
            scrollView.addSubview(label)
            scrollView.contentSize = CGSize(width: 0, height: height + 15)
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
