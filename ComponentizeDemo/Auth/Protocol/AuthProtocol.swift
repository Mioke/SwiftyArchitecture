import Foundation
import MIOSwiftyArchitecture
import RxSwift

public class TestUser: UserProtocol, Codable {
    
    public var id: String
    public var age: Int
    public var token: String
    public var expiration: Date?
    
    public static let modelVersion: Int = 1
    
    public enum CodingKeys: CodingKey {
        case id
        case age
        case token
        case expiration
    }
    
    public init(id: String, age: Int, token: String) {
        self.id = id
        self.age = age
        self.token = token
        self.expiration = Date().offsetWeek(1)
    }
}

extension TestUser {
    public var customDebugDescription: String {
        return "id - \(id), age - \(age)\ntoken: \(token)"
    }
}

public protocol AuthServiceProtocol {
    func authenticate(completion: @escaping (TestUser) -> ()) throws
    func deauthenticate(completion: @escaping (Error?) -> Void)
    func refreshAuthenticationIfNeeded(completion: @escaping (TestUser) -> ()) -> Void
}

public extension ModuleIdentifier {
    static let auth: ModuleIdentifier = "com.klein.module.auth"
}
