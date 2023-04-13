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
    
    var userMeta: _UserMeta? = nil
    
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
    
    public func setup(authDelegate: AuthControllerDelegate) -> Void {
        // set auth delegate first.
        AppContext.authController.delegate = authDelegate
        
        // load user meta, synchronously
        loadUserMeta().then(self.refreshAuthenticationIfNeeded)
            .subscribe()
            .disposed(by: disposables)
        KitLogger.info("Standard app context setup completed.")
    }
    
    func refreshAuthenticationIfNeeded() -> ObservableSignal {
        guard let value = AppContext.current.authState.value, value == .presession else { return .signal }
        return refreshAuthentication(isStartup: true)
    }
    
    func refreshAuthentication(isStartup: Bool) -> ObservableSignal {
        let user = AppContext.current.user
        guard let delegate = AppContext.authController.delegate,
              delegate.shouldRefreshAuthentication(with: user, isStartup: isStartup)
        else {
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
        return self.store.object(with: StandardAppContext.userMetaKey, type: _UserMeta.self)
            .do(onNext: { [weak self] meta in
                guard let self = self, meta == nil else { return }
                KitLogger.info("No previous user meta, creating one and going to save it.")
                self.createOrUpdateUserMata(with: self.userId).subscribe().disposed(by: self.disposables)
            })
            .compactMap({ meta -> String? in
                return meta?.currentUserId == DefaultUser._id ? nil : meta?.currentUserId
            })
            .flatMapLatest({ [weak self] userId -> Observable<UserProtocol?> in
                guard let self = self else { return .deallocatedError }
                return self.loadArchivedUser(with: userId)
            })
            .flatMapLatest { user -> ObservableSignal in
                if let user = user {
                    KitLogger.info("Loaded previous user meta, going to create a new app context with the user.")
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
            ob.onNext(meta)
            return Disposables.create()
        }
        .flatMapLatest { [weak self] meta -> ObservableSignal in
            guard let self = self else { return .error(todo_error()) }
            return self.store.upsert(object: meta)
        }
        .do { _ in
            KitLogger.info("Update meta with user id - \(userId)")
        }
    }
    
    var defaultUser: DefaultUser {
        return self.user as! DefaultUser
    }
}

// MARK: - user storage

public protocol StandardAppContextStoreProtocol: AnyObject {
    func standardAppContext(_ context: AppContext, migrate userData: Data, from version: Int) -> (any UserProtocol)?
}

extension StandardAppContext {
    
    func loadArchivedUser(with userId: String) -> Observable<UserProtocol?> {
        return self.store.object(with: userId, type: _UserData.self)
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
        return self.store.upsert(object: user).subscribe(observer)
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


