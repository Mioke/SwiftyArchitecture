//
//  UserContext.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/2/16.
//

import UIKit
import RxSwift
import RealmSwift

public protocol UserProtocol: DataConvertible {
    /// The identifier of a user, the primary key of the conversion data of the user model.
    var id: String { get set }
    
    /// Your customized user model version. Because of sometimes your user model will got updated when your code grows,
    /// like from `Userv1` to `Userv2` it will add more properties in it, so when the model changes, please update this
    /// version number to a new one (larger), and the setup process will let you go into a migration process.
    static var modelVersion: Int { get }
}

/// The authentication states.
public enum AuthState {
    /// Not logged in, has no session or user data.
    case unauthenticated
    /// Logged in and stored all the newest user data.
    case authenticated
    /// Has previous user's data but the application has already restarted, needs to be refreshed.
    case presession
}

public protocol AuthControllerDelegate: AnyObject {
    /// Called when Standard AppContext is demanded to trigger a new user login process.
    /// - Returns: The authentication process.
    func authenticate() -> Observable<UserProtocol>
    
    /// When the Standard AppContext found a user context cache in sandbox, or `refreshAuthentication` is called,
    /// this function will be called to decide whether the user context should be refreshed.
    /// - Parameters:
    ///   - user: The previous user data.
    ///   - isStartup: is called from application start process.
    /// - Returns: A decission of whether should refresh the user data.
    func shouldRefreshAuthentication(with user: UserProtocol, isStartup: Bool) -> Bool
    
    /// Called when there is needed to refresh the current user context.
    /// - Parameter user: The old user data.
    /// - Returns: The refresh process and return a new user in the end.
    func refreshAuthentication(with user: UserProtocol) -> Observable<UserProtocol>
    
    /// Called when the AppContext is logging out.
    /// - Returns: The deauthentication process.
    func deauthenticate() -> ObservableSignal
}

public class AuthController: NSObject {
    
    public weak var delegate: AuthControllerDelegate?
    
    init(delegate: AuthControllerDelegate?) {
        self.delegate = delegate
    }
}

class DefaultUser: UserProtocol, Codable {
    static let _id = "__standard__"
    static let modelVersion: Int = 1
    
    var id: String = DefaultUser._id
    
    enum CodingKeys: CodingKey {
        case id
    }
}

class _UserMeta: Object {
    @Persisted(primaryKey: true) var key: Int
    @Persisted var currentUserId: String
    @Persisted var isLoggedIn: Bool
}

class _UserData: Object {
    @Persisted(primaryKey: true) var userId: String
    @Persisted var codableData: Foundation.Data
    @Persisted var version: Int
}

class _User {
    struct Wrapper: Codable {
        var `class`: String
        var data: Foundation.Data
    }
}

