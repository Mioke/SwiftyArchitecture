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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let me = User(id: "15780", name: "Klein")
            completion(me)
        }
    }
    
    func deauthenticate(completion: @escaping (Error?) -> Void) {
        
    }
}
