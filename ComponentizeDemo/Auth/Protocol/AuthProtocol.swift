import Foundation
import MIOSwiftyArchitecture

public struct User {
    public let id: String
    public let name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public protocol AuthProtocol {
    func authenticate(completion: @escaping (User) -> ()) throws
    func deauthenticate(completion: @escaping (Error?) -> Void)
}

public extension ModuleIdentifier {
    static let auth: ModuleIdentifier = "com.klein.module.auth"
}
