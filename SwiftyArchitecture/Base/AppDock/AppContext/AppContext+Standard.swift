//
//  AppContext+Standard.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/8/31.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa

final public class StandardAppContext: AppContext {
    
    let disposables: DisposeBag = .init()
    
    convenience init() {
        self.init(user: DefaultUser(), storeVersions: .init(cacheVersion: 1, persistanceVersion: 1))
        self.authState.onNext(.authenticated)
    }
    
    /// The configuration of app context.
    public var contextConfiguration: StandardAppContext.Configuration = .init(archiveLocation: .database)
    
    public weak var migrateDelegate: StandardAppContextStoreProtocol?
    
    public let resourceBag: DisposeBag = .init()
    
    private let writeSchedule: SerialDispatchQueueScheduler = .init(internalSerialQueueName: "com.authcontroller.write")
    
    public struct Configuration: Codable {
        public enum InfoArchiveLocation: Codable {
            case file(path: String)
            case database
        }
        public let archiveLocation: InfoArchiveLocation
        
        public init(archiveLocation: InfoArchiveLocation) {
            self.archiveLocation = archiveLocation
        }
    }
    
    // MARK: - Public APIs
    
    /// Setup all delegates and run necessary processes:
    ///  1. Try to load user's meta data if there is one
    ///  2. Refresh the authentication if the user data is valid.
    ///
    /// - Important: Must setup this function before use AppContext.
    ///
    /// - Parameters:
    ///   - authDelegate: The authentication controller's delegate.
    ///   - migrateDelegate: The user data migration delegate.
    public func setup(authDelegate: AuthControllerDelegate, migrateDelegate: StandardAppContextStoreProtocol) -> Void {
        // set auth delegate first.
        AppContext.authController.delegate = authDelegate
        
        self.migrateDelegate = migrateDelegate
        
        // load user meta, synchronously
        loadUserMeta().then(refreshAuthenticationIfNeeded)
            .subscribe()
            .disposed(by: disposables)
        KitLogger.info("Standard app context setup completed.")
    }
    
    /// Trigger a login action, will try to request to delegate for processing custom authentication.
    /// - Returns: A process signal.
    public func triggerLogin() -> ObservableSignal {
        guard AppContext.current == AppContext.standard else { return .error(KitErrors.alreadyAuthenticated) }
        guard let delegate = AppContext.authController.delegate else { return .error(KitErrors.noDelegateError) }
        return delegate.authenticate()
            .do(onNext: { user in
                AppContext.startAppContext(with: user, storeVersions: AppContext.Consts.storeVersions)
            })
            .mapToSignal()
    }
    
    /// Trigger the log out process.
    /// - Returns: The log out process signal.
    public override func logout() -> ObservableSignal {
        assertionFailure("StandardAppContext can't be logged out, please check the method call by using `AppContext.current.logout()` and current is not a standard AppContext.")
        return .never()
    }
    
    // MARK: - Internal helper functions
    
    func refreshAuthenticationIfNeeded() -> ObservableSignal {
        guard let value = AppContext.current.authState.value, value == .presession else { return .signal }
        return refreshAuthentication(isStartup: true)
    }
    
    func refreshAuthentication(isStartup: Bool) -> ObservableSignal {
        let user = AppContext.current.user
        guard let delegate = AppContext.authController.delegate else { return .error(KitErrors.noDelegateError) }
        
        guard delegate.shouldRefreshAuthentication(with: user, isStartup: isStartup) else {
            KitLogger.info("`shouldRefreshAuthentication(with:)` returns false, don't need to refresh authentication.")
            return .signal
        }
        
        KitLogger.info("Begin refresh authentication...")
        return delegate.refreshAuthentication(with: user)
            .do(onNext: { _ in
                KitLogger.info("Refresh authentication complete")
            }, onError: { error in
                KitLogger.error("Refresh authentication error: \(error)")
            })
            .flatMapLatest { user -> ObservableSignal in
                guard user.id == AppContext.current.userId else { return .error(todo_error()) }
                AppContext.current.authState.onNext(.authenticated)
                return AppContext.current.update(user: user)
                    .do { _ in KitLogger.info("Record fresh user complete.") }
            }
    }
    
    deinit {
    }
    
    static let userMetaKey: Int = 1
    
    func loadUserMeta() -> ObservableSignal {
        return fetchUserMeta()
            .do(onNext: { [weak self] meta in
                // Create a meta data of the new user context. During the first launch it would
                // create a default user's meta, then when a new user account has logged in, it
                // will call
                guard let self, meta == nil else { return }
                KitLogger.info("No previous user meta, creating one and going to save it.")
                createOrUpdateUserMata(with: self.userId).subscribe().disposed(by: self.disposables)
            })
            .compactMap { meta -> String? in
                // filter default user, only try to load the normal user account.
                if meta?.currentUserId == DefaultUser._id { return nil }
                // Only the user which has been logged in previously can be loaded.
                if meta?.isLoggedIn == true { return meta?.currentUserId }
                return nil
            }
            .flatMapLatest { [weak self] userId -> Observable<UserProtocol?> in
                guard let self else { return .deallocatedError }
                return loadArchivedUser(with: userId)
            }
            .flatMapLatest { user -> ObservableSignal in
                if let user = user {
                    KitLogger.info("Loaded previous user(\(user.id)) meta, going to create a new app context with the user.")
                    let newAppContext = AppContext(user: user, storeVersions: AppContext.Consts.storeVersions)
                    newAppContext.authState.onNext(.presession)
                    AppContext.current = newAppContext
                }
                return .signal
            }
    }
    
    func createOrUpdateUserMata(with userId: String) -> ObservableSignal {
        return Observable<_UserMeta>.create { ob in
            let meta = _UserMeta()
            meta.key = StandardAppContext.userMetaKey
            meta.currentUserId = userId
            meta.isLoggedIn = true
            ob.onNext(meta)
            return Disposables.create()
        }
        .flatMapLatest { [weak self] meta -> ObservableSignal in
            guard let self else { throw KitErrors.deallocated }
            return persist.upsert(object: meta)
        }
        .do { _ in
            KitLogger.info("Updated meta with user id - \(userId)")
        }
    }
    
    func updateUserMeta(with block: @escaping (_UserMeta) -> Void) -> ObservableSignal {
        fetchUserMeta().flatMapLatest { [weak self] maybeData -> ObservableSignal in
            guard let self else { return .never() }
            guard let meta = maybeData else { return .error(KitErrors.notFound) }
            return persist.update { _ in block(meta) }
        }
    }
    
    func fetchUserMeta() -> Observable<_UserMeta?> {
        return persist.object(with: StandardAppContext.userMetaKey, type: _UserMeta.self)
        // No need to listen to the changes.
            .take(1)
    }
    
    var defaultUser: DefaultUser {
        return self.user as! DefaultUser
    }
}

// MARK: - User storage

public protocol StandardAppContextStoreProtocol: AnyObject {
    func standardAppContext(_ context: AppContext, migrate userData: Data, from version: Int) -> UserProtocol?
}

extension StandardAppContext {
    
    private func loadArchivedUser(with userId: String) -> Observable<UserProtocol?> {
        return persist.object(with: userId, type: _UserData.self)
            .take(1)
            .flatMapLatest { data -> Observable<UserProtocol?> in
                guard let data = data else { return .just(nil) }
                guard let wrapper = try? JSONDecoder().decode(_User.Wrapper.self, from: data.codableData) else {
                    return .just(nil)
                }
                guard let clazz = NSClassFromString(wrapper.class) as? UserProtocol.Type else {
                    return .error(todo_error())
                }
                // check version
                if let checkResult = self.checkVersion(with: data, userClass: clazz) {
                    return checkResult
                }
                let archivedUser = try clazz.object(from: wrapper.data)
                return .just(archivedUser)
            }
    }
    
    func checkVersion(with data: _UserData, userClass: UserProtocol.Type) -> Observable<UserProtocol?>? {
        guard data.version != userClass.modelVersion else { return nil }
        if let migrateDelegate = self.migrateDelegate,
           let user = migrateDelegate.standardAppContext(self,
                                                         migrate: data.codableData,
                                                         from: data.version) {
            return updateArchived(userData: data, with: user).flatMapLatest { _ in
                return Observable<UserProtocol?>.just(user)
            }
        } else {
            return .just(nil)
        }
    }
    
    func archive(appContext: AppContext) -> ObservableSignal {
        return ObservableSignal.create { observer in
            let data: Data
            do {
                let opaque: _User.Wrapper = .init(class: String(reflecting: appContext.user),
                                                  data: try appContext.user.data())
                data = try JSONEncoder().encode(opaque)
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
            
            switch self.contextConfiguration.archiveLocation {
            case .file(path: let path):
                return self.archive(data: data, path: path, observer: observer)
            case .database:
                return self.archiveInDatabase(data: data, appContext: appContext, observer: observer)
            }
        }
    }
    
    func archiveInDatabase(data: Data, appContext: AppContext, observer: AnyObserver<Void>) -> Disposable {
        let user = _UserData()
        user.codableData = data
        user.userId = appContext.userId
        user.version = type(of: appContext.user).modelVersion
        return persist.upsert(object: user).subscribe(observer)
    }
    
    func updateArchived(userData: _UserData, with user: UserProtocol) -> ObservableSignal {
        return .create { observer in
            do {
                try self.store.cache.realm.safeWrite { _ in
                    userData.version = type(of: user).modelVersion
                    userData.codableData = try user.data()
                }
                observer.onNext(()); observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
        .subscribe(on: CurrentThreadScheduler.instance)
    }
    
    // TODO: - not complete
    func archive(data: Data, path: String, observer: AnyObserver<Void>) -> Disposable {
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch let e {
            observer.onError(e)
        }
        observer.onCompleted()
        return Disposables.create()
    }
}

// MARK: - Public API for user records

public struct UserData {
    public let userId: String
    public let codableData: Foundation.Data
    public let version: Int
    
    init(from innerModel: _UserData) {
        self.userId = innerModel.userId
        self.codableData = innerModel.codableData
        self.version = innerModel.version
    }
}

public extension StandardAppContext {
    
    /// Get all users who have logged in before or currently is logged in.
    /// - Returns: The observable result of a list of `UserData`.
    func fetchHistoryUserList() -> Observable<[UserData]> {
        persist.objects(with: _UserData.self)
            .map { $0.map { UserData(from: $0) } }
    }
    
    /// Clean all inactive users' data.
    /// - Returns: Process signal.
    func cleanHistoryUserList() -> ObservableSignal {
        if AppContext.current != self {
            return persist.delete(with: _UserData.self) { query in
                return query.userId != AppContext.current.userId
            }
        } else {
            return persist.deleteAll(_UserData.self)
        }
    }
    
}
