//
//  SystemLogBrowser.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 3/8/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit

class SystemLogBrowser: UIViewController {
    
    var fileName: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        guard self.fileName != nil else {
            fatalError("file name must not be nil")
        }
        
        self.title = self.fileName
        self.view.backgroundColor = UIColor.whiteColor()
        
        if let content = SystemLog.contentsOfFile(self.fileName) {
            
            let scrollView = UIScrollView(frame: self.view.bounds)
            self.view.addSubview(scrollView)
            
            let attributeText = NSAttributedString(string: content, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(10)])
            let height = attributeText.boundingRectWithSize(CGSizeMake(UIScreen.mainScreen().bounds.size.width - 30, 99999), options: .UsesLineFragmentOrigin, context: nil).height
            
            let label = UILabel(frame: CGRectMake(15, 15, UIScreen.mainScreen().bounds.size.width - 30, height))
            label.numberOfLines = 0
            label.attributedText = attributeText
            
            scrollView.addSubview(label)
            scrollView.contentSize = CGSizeMake(0, height + 15)
        }
    }

    override func didReceiveMemoryWarning() {
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
