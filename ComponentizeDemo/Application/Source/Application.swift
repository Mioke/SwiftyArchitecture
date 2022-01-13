import Foundation
import MIOSwiftyArchitecture
import ApplicationProtocol
import AuthProtocol

class ApplicationModule: ModuleProtocol, ApplicationProtocol {
    
    static var moduleIdentifier: ModuleIdentifier {
        return .application
    }
    required init() { }
    
    func moduleDidLoad(with manager: ModuleManager) {
        if let user = manager.session?.userID {
            print(user)
        }
    }
    
    func startApplication() {
        guard let authModule = try? moduleManager?.bridge.resolve(.auth) as? AuthProtocol else {
            fatalError()
        }
        try? authModule.authenticate { [unowned self] user in
            ModuleManager.default.beginUserSession(with: user.id)
            self.markAsReleasing()
        }
    }
    
}
