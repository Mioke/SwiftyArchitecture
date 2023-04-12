//
//  UserContext.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/2/16.
//

import UIKit
import RxSwift
import RealmSwift

public protocol UserProtocol: DataConversion {
    /// The identifier of a user, the primary key of the conversion data of the user model.
    var id: String { get set }
    /// The state indicate the user session. This property should not be record, so if your user model self is
    /// `Codable`, please remove this from coding keys.
    var authState: BehaviorSubject<AuthState> { get }
    /// The configuration of app context.
    var contextConfiguration: StandardAppContext.Configuration { get }
}

public enum AuthState {
    case unauthenticated
    case authenticated
    case presession
}

public protocol AuthControllerDelegate: AnyObject {
    func shouldRefreshAuthentication(with user: UserProtocol, isStartup: Bool) -> Bool
    func refreshAuthentication(with user: UserProtocol) -> Observable<UserProtocol>
    func deauthenticate() -> ObservableSignal
}

public class AuthController: NSObject {
    
    public weak var delegate: AuthControllerDelegate?
    
    private let disposeBag = DisposeBag()
    
    init(delegate: AuthControllerDelegate?) {
        self.delegate = delegate
    }
}

class DefaultUser: UserProtocol, Codable {
    static let _id = "__standard__"
    var contextConfiguration: StandardAppContext.Configuration = .init(archiveLocation: .database)
    
    var authState: BehaviorSubject<AuthState> = .init(value: .authenticated)
    var id: String = DefaultUser._id
    
    enum CodingKeys: CodingKey {
        case id
    }
}

class _UserMeta: Object {
    @Persisted(primaryKey: true) var key: Int
    @Persisted var currentUserId: String
}

class _UserData: Object {
    @Persisted(primaryKey: true) var userId: String
    @Persisted var codableData: Foundation.Data
}

class _User {
    struct Wrapper: Codable {
        var `class`: String
        var data: Foundation.Data
    }
}

