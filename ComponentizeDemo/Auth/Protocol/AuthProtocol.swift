import Foundation
import MIOSwiftyArchitecture
import RxSwift

final public class User: UserProtocol, Codable {
    public static var modelVersion: Int = 1
    
    public var id: String
    public var name: String?
    
    public init(id: String) {
        self.id = id
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
    }
}

public protocol AuthServiceProtocol {
    func authenticate(completion: @escaping (User) -> ()) throws
    func deauthenticate(completion: @escaping (Error?) -> Void)
    func refreshAuthenticationIfNeeded(completion: @escaping (User) -> ()) -> Void
}

public extension ModuleIdentifier {
    static let auth: ModuleIdentifier = "com.klein.module.auth"
}
