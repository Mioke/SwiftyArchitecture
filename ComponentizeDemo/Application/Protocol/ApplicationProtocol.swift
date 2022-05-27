import Foundation
import MIOSwiftyArchitecture

public protocol ApplicationProtocol {
    func startApplication()
}

public extension ModuleIdentifier {
    static let application: ModuleIdentifier = "com.klein.module.application"
}
