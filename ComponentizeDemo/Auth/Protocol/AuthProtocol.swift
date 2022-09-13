import Foundation
import MIOSwiftyArchitecture
import RxSwift

final public class User: UserProtocol, Codable {
    public var id: String
    public var authState: BehaviorSubject<AuthState> = .init(value: .unauthenticated)
    public var contextConfiguration: StandardAppContext.Configuration = .init(archiveLocation: .database)
    public var name: String?
    
    public init(id: String) {
        self.id = id
    }
    
    enum CodingKeys: CodingKey {
        case id
        case contextConfiguration
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
