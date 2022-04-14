import Foundation
import MIOSwiftyArchitecture
import AuthProtocol

class AuthModule: ModuleProtocol, AuthProtocol {
    
    static var moduleIdentifier: ModuleIdentifier {
        return .auth
    }
    required init() { }
    
    func moduleDidLoad(with manager: ModuleManager) {
        
    }
    
    func authenticate(completion: @escaping (User) -> ()) throws {
        let user = User(id: "15780")
        ModuleManager.default.beginUserSession(with: user.id)
        self.markAsReleasing()
    }
    
    func refreshAuthenticationIfNeeded(completion: @escaping (User) -> ()) {
        if let previousUID = AppContext.standard.previousLaunchedUserId {
            let previousUser = User(id: previousUID)
            let previousContext = AppContext(user: previousUser)
            // get token from previous context data center, like:
            // let credential = previousContext.dataCenter.object(with: previousUID, type: Credential.Type)
            print(previousContext)
            // and then do some refresh token logic here.
        }
    }
    
    func deauthenticate(completion: @escaping (Error?) -> Void) {
        
    }
}
