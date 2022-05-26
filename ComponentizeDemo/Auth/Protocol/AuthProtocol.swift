import Foundation
import MIOSwiftyArchitecture
import RxSwift

public class User: UserProtocol {
    public var id: String
    public var authState: BehaviorSubject<AuthState> = .init(value: .unauthenticated)
    public var authConfiguration: AuthController.Configuration = .init(archiveLocation: .database)
    public var archivableInfo: UserArchivableInfoProtocol = UserArchiveInfo()
    public var name: String?
    
    public init(id: String) {
        self.id = id
    }
}

class UserArchiveInfo: UserArchivableInfoProtocol {
    static func decode(_ data: Data) throws -> Self {
        try JSONDecoder().decode(self, from: data)
    }
    public func encode() throws -> Data {
        try JSONEncoder().encode(self)
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
