//
//  Navigation+PageGroup.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2023/4/7.
//

import Foundation

extension Navigation {
    
    func validatePageGroupFunction() throws {
        if !enablePageGroup {
            throw NavigationError.pageGroupDisabled
        }
    }
    
    public func popCurrentPageGroup(animated: Bool) throws -> Void {
        try validatePageGroupFunction()
        guard let current = pageGroupStack.pop(), let root = current.beginIndex else {
            return
        }
        switch current.presentationMode {
        case .present(style: _):
            root.dismiss(animated: animated)
        case .push:
            guard let nav = root.navigationController,
                  let index = nav.viewControllers.firstIndex(of: root),
                  index > 0
            else { return }
            root.navigationController?.popToViewController(nav.viewControllers[index - 1], animated: animated)
        }
    }
    
    public func pop(to pageGroup: Navigation.PageGroup) throws {
        try validatePageGroupFunction()
    }
    
    
}
