import Foundation
import MIOSwiftyArchitecture
import ApplicationProtocol
import AuthProtocol
import RxSwift

class ApplicationModule: ModuleProtocol, ApplicationProtocol {
    
    static var moduleIdentifier: ModuleIdentifier {
        return .application
    }
    required init() { }
    
    let disposeBag = DisposeBag()
    
    func moduleDidLoad(with manager: ModuleManager) {
        if let user = manager.session?.userID {
            print(user)
        }
    }
    
    func startApplication() {
        AppContext.standard
            .setup()
            .subscribe { finished in
                print(AppContext.standard.previousLaunchedUserId as Any)
                guard let authModule = try? self.moduleManager?.bridge.resolve(.auth) as? AuthProtocol else {
                    fatalError()
                }
                if let _ = AppContext.standard.previousLaunchedUserId {
                    authModule.refreshAuthenticationIfNeeded(completion: { user in
                        print(user)
                    })
                }
            }
            .disposed(by: disposeBag)
    }
    
}
