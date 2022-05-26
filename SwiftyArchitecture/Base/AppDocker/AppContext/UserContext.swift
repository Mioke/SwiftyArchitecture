//
//  UserContext.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/2/16.
//

import UIKit
import RxSwift
import RealmSwift

public protocol AuthControllerDelegate: AnyObject {
    func authenticate() -> Observable<Void>
    func deauthenticate() -> Observable<Void>
}


public class AuthController: NSObject {
    
    public struct Configuration {
        public enum InfoArchiveLocation {
            case file(path: String)
            case database
        }
        public let archiveLocation: InfoArchiveLocation
        
        public init(archiveLocation: InfoArchiveLocation) {
            self.archiveLocation = archiveLocation
        }
    }
    
    let configuration: AuthController.Configuration
    weak var delegate: AuthControllerDelegate?
    
    private let disposeBag = DisposeBag()
    
    private let writeSchedule: SerialDispatchQueueScheduler = .init(internalSerialQueueName: "com.authcontroller.write")
    
    init(configuration: AuthController.Configuration) {
        self.configuration = configuration
    }
    
    func loadArchivedData(appContext: AppContext) -> Observable<Bool> {
        return appContext.dataCenter.object(with: appContext.user.id, type: UserArchiveData.self)
//            .observe(on: <#T##ImmediateSchedulerType#>)
            .flatMapLatest { data -> Observable<Bool> in
                guard let data = data else { return .just(true) }
                guard let decoded = try? type(of: appContext.user.archivableInfo).decode(data.archivedData) else {
                    return .just(false)
                }
                appContext.user.archivableInfo = decoded
                appContext.user.authState.onNext(.presession)
                return .just(true)
            }
    }
    
    func auth(appContext: AppContext) throws -> Observable<Void> {
        guard let delegate = delegate else {
            throw AppDockerError.noDelegateError
        }
        return delegate.authenticate().flatMapLatest {
            return self.changeUserState(to: .authenticated, appContext: appContext)
        }
    }
    
    func archive(appContext: AppContext) -> Observable<Void> {
        return Observable<Void>.create { observer in
            let data: Data
            do {
                data = try appContext.user.archivableInfo.encode()
            } catch {
                observer.onError(error)
                return Disposables.create()
            }
            
            switch self.configuration.archiveLocation {
            case .file(path: let path):
                return self.archive(data: data, path: path, observer: observer)
            case .database:
                return self.archiveInDatabase(data: data, appContext: appContext, observer: observer)
            }
        }
        .subscribe(on: writeSchedule)
    }
    
    func archiveInDatabase(data: Data, appContext: AppContext, observer: AnyObserver<Void>) -> Disposable {
        let user = UserArchiveData()
        user.archivedData = data
        user.userId = appContext.userId
        return appContext.dataCenter.upsert(object: user).subscribe(observer)
    }
    
    func archive(data: Data, path: String, observer: AnyObserver<Void>) -> Disposable {
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch let e {
            observer.onError(e)
        }
        observer.onCompleted()
        return Disposables.create()
    }
    
    func changeUserState(to state: AuthState, appContext: AppContext) -> Observable<Void> {
        defer {
            appContext.user.authState.onNext(state)
        }
        return appContext.user.authState
            .asObservable()
            .take(1)
            .map { _ in () }
    }
}

class UserArchiveData: Object {
    @Persisted(primaryKey: true) var userId: String
    @Persisted var archivedData: Data
}
