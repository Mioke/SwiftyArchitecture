//
//  AppContext.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift

public let kAppContextChangedNotification = NSNotification.Name(rawValue: "kAppContextChangedNotification")

public class AppContext: NSObject {
    
    public static let standard: StandardAppContext = .init()
    public static var current: AppContext = standard {
        didSet {
            guard oldValue != current else { return }
            NotificationCenter.default.post(name: kAppContextChangedNotification, object: current)
        }
    }

    // MARK: - User
    public internal(set) var user: UserProtocol
    
    public var userId: String {
        return user.id
    }
    
    public init(user: UserProtocol) {
        self.user = user
        authController = .init(configuration: user.authConfiguration)
        super.init()
        self.dataCenter = DataCenter(appContext: self)
    }
    
    let authController: AuthController
    
    public weak var authDelegate: AuthControllerDelegate? {
        didSet {
            authController.delegate = authDelegate
        }
    }
    
    // MARK: - Data Center
    public var dataCenter: DataCenter!
}

public protocol UserArchivableInfoProtocol: Codable {
    static func decode(_ data: Data) throws -> Self
    func encode() throws -> Data
}

public protocol UserProtocol {
    
    var id: String { get set }
    
    var authState: BehaviorSubject<AuthState> { get set }
    
    var authConfiguration: AuthController.Configuration { get }
    
    var archivableInfo: UserArchivableInfoProtocol { get set }
}

public enum AuthState {
    case unauthenticated
    case authenticated
    case presession
}

final public class StandardAppContext: AppContext {
    
    convenience init() {
        self.init(user: DefaultUser())
    }
    
    public let resourceBag: DisposeBag = .init()
    
    private var isInfoLoaded: Bool = false
    
    private override init(user: UserProtocol) {
        super.init(user: user)
    }
    
    public func setup() -> Observable<Bool> {
        return authController.loadArchivedData(appContext: self)
            .do { self.isInfoLoaded = $0 }
    }
    
    var defaultUser: DefaultUser {
        return self.user as! DefaultUser
    }
    
    public var previousLaunchedUserId: String? {
        return isInfoLoaded ? defaultUser._archivableInfo.previousLaunchedUserId : nil
    }
}

class DefaultUser: UserProtocol {
    var authConfiguration: AuthController.Configuration = .init(archiveLocation: .database)
    
    var authState: BehaviorSubject<AuthState> = .init(value: .authenticated)
    var id: String = "__standard__"
    
    var archivableInfo: UserArchivableInfoProtocol {
        get { return _archivableInfo }
        set {
            guard let newValue = newValue as? DefaultUserArchivableInfo else { return }
            _archivableInfo = newValue
        }
    }
    
    lazy var _archivableInfo: DefaultUserArchivableInfo = .init(previousLaunchedUserId: id)
}

struct DefaultUserArchivableInfo: UserArchivableInfoProtocol {
    let previousLaunchedUserId: String

    static func decode(_ data: Data) throws -> DefaultUserArchivableInfo {
        try JSONDecoder().decode(self, from: data)
    }
    public func encode() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

// MARK: - Convenience
public func AppContextCurrentDatabase() -> Realm {
    return AppContext.current.dataCenter.db.realm
}

public func AppContextCurrentMemory() -> Realm {
    return AppContext.current.dataCenter.memory.realm
}
