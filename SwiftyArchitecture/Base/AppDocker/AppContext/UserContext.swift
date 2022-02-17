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
    
    let configuration: Configuration
    weak var delegate: AuthControllerDelegate?
    
    private let disposeBag = DisposeBag()
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    func loadPreviousSession(appContext: AppContext) throws {
        guard appContext.user.authState.value == .unauthenticated else {
            return
        }
        switch self.configuration.archiveLocation {
        case .file(let path):
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            appContext.user.archivableInfo = try appContext.user.archivableInfoType.decode(data)
            appContext.user.authState.onNext(.presession)
        case .database:
            // TODO: - here should read the previous user's data center.
            appContext.dataCenter.object(with: appContext.user.userId, type: UserArchiveData.self)
                .subscribe(onNext: { data in
                    guard let data = data,
                          let decoded = try? appContext.user.archivableInfoType.decode(data.archivedData) else {
                              return
                          }
                    appContext.user.archivableInfo = decoded
                    appContext.user.authState.onNext(.presession)
                })
                .disposed(by: disposeBag)
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

private class UserArchiveData: Object {
    @Persisted(primaryKey: true) var userId: String
    @Persisted var archivedData: Data
}
