//
//  UserModel.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/2.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import RxRealm
import RealmSwift
import RxSwift
import Alamofire
import MIOSwiftyArchitecture
//import YYModel

// ************* DEPRECATING BEGIN ****************

//class UserModel: NSObject, RecordProtocol {
//    
//    var userName: String = ""
//    var userID: Int = 0
//    
//    convenience init(name: String, uid: Int) {
//        self.init()
//        
//        self.userName = name
//        self.userID = uid
//    }
//    
//    // MARK: - RecordProtocol delegate
//    func dictionaryRepresentation(in table: TableProtocol) -> [String : Any]? {
//        if table is UserTable {
//            return [
//                "user_name": self.userName,
//                "user_id": self.userID
//            ]
//        }
//        return nil
//    }
//    
//    override required init() {
//        super.init()
//    }
//    
//    static func generate(withDictionary dictionary: [AnyHashable: Any], fromTable table: TableProtocol) -> Self? {
//        
//        if table is UserTable {
//            guard let uid = dictionary["user_id"] as? Int, let name = dictionary["user_name"] as? String else {
//                return nil
//            }
//            // - Only use `self.init()` and must have a `required init()` that can return `Self` in this function
//            // - Or mark this class as `final` and replace `Self` to Class name.
//            // Both just fine now, but it's not cool, tring to find a perfect way to solve this problem.
//            let model = self.init()
//            model.userID = uid
//            model.userName = name
//            
//            return model
//        }
//        return nil
//    }
//}

// ************* DEPRECATING END ****************


final class TestObj: Object {
    // When using Realm from Swift, the Swift.reflect(_:) function is used to determine information
    // about your models, which requires that calling init() succeed. This means that all
    // non-optional properties must have a default value.
    @objc dynamic var key: String = ""
    @objc dynamic var value: Int = 0

    init(with key: String) {
        self.key = key
        super.init()
    }
    
    override class func primaryKey() -> String? {
        return "key"
    }
    
    required override init() {
        super.init()
    }
    
    func kopy() -> TestObj {
        let obj = TestObj(with: key)
        obj.value = self.value
        return obj
    }
    
    enum CodingKeys: String, CodingKey {
        case key = "k"
        case value = "v"
    }
}

extension TestObj: Codable {
    
}

extension TestObj: Comparable {
    static func < (lhs: TestObj, rhs: TestObj) -> Bool {
        return lhs.value < rhs.value
    }
}

extension TestObj: DataCenterManaged {
    typealias APIInfo = TestAPI

    static func serialize(data: TestAPI.Result) throws -> [Object] {
        return data.objects as [Object]
    }
}

class User: Object {
    @Persisted(primaryKey: true)
    var userId: String = ""
    @Persisted
    var name: String = ""
}

final class UserAPI: NSObject, ApiInfoProtocol {
    
    struct Param: Codable {
        let uids: [String]
    }
    
    typealias RequestParam = UserAPI.Param
    
    typealias ResultType = Reply
    
    struct Reply: Codable {
        
        struct User: Codable {
            var userId: String
            var name: String
            var version: String?
        }
        var users: [Reply.User]
    }
    
    static var apiVersion: String {
        get { return "v1" }
    }
    static var apiName: String {
        get { return "getUserInfo" }
    }
    static var server: Server {
        get { return MioDemoServer }
    }
    static var httpMethod: Alamofire.HTTPMethod {
        get { return .get }
    }
    
    static var responseSerializer: MIOSwiftyArchitecture.ResponseSerializer<Reply> {
        return MIOSwiftyArchitecture.JSONCodableResponseSerializer<Reply>()
    }
}

extension User: DataCenterManaged {
    
    static func serialize(data: UserAPI.Reply) throws -> [RealmSwift.Object] {
        let result: [Object] = data.users.map { item in
            let user = User()
            user.name = item.name
            user.userId = item.userId
            return user
        }
        
        let addition = TestObj()
        addition.key = "Klein"
        addition.value = 10025
        
        return result + [addition]
    }
    
    
    typealias APIInfo = UserAPI
    
}
