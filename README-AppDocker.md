#  SwiftyArchitecture - App Dock

## App Context

When an application has messive functionalities, developers may want to store some data relative to single users. The `App Context` defines a context for each user. When an application starts, there will be a standard app context created by this framework, named `StandardAppContext`:

```swift
public class AppContext: NSObject {
    public static let standard: StandardAppContext = .init()
}
``` 

The standard app context also have a serials of functions for you to manage current context, like store default data in non-user-relative database.

## User Context

There is a default user or an anonymous user for user context before the user login journey, which stored in standard app context. But you can put no attention on it.

### Authentication Control

Authentication control is a workflow which to manage the authentication states of a exsiting user cross application sessions.

When you want to do anything about authentication, first, you should guaranttee you have set up an `AuthController` for your standard app context.

```swift
// For example: in AppDelegate.swift application(_:didFinishLaunchingWithOptions:) -> Bool
if let standardContext = AppContext.current as? StandardAppContext {
    standardContext.contextConfiguration = .init(archiveLocation: .database)
    standardContext.setup(authDelegate: UserService.shared)
}
```

#### Create a new AppContext

Then when you want to start a new app context, try this:
```swift
loginAPI.response { user in
    AppContext.startAppContext(with: user, storeVersions: AppContext.Consts.storeVersions)
}
```
> Attention: `startAppContext(with:storeVersions:)` start a new context with `authState` is `.authenticated`, so do login first and then start a new context.

After creation is complete, the new AppContext will automatically stored in a store which managed by `StandardAppContext`, the content of data contains the `user` model informations, so your `User` model is data-convertible.

#### Restore an old AppContext

The restoration is automatically performed after the `setup(authDelegate:)` function called, but only if there is an old AppContext stored before.

Once the restoration process is complete, the old AppContext will be created and the authentication state will remain as `.presession` until the authentication is refreshed. The refreshing procedure will be delegated to the `authDelegate` that you have set up.

For example:

```swift
extension UserService: AuthControllerDelegate {
    func shouldRefreshAuthentication(with user: UserProtocol, isStartup: Bool) -> Bool {
        // we can refresh authentication everytime when app startup.
        if isStartup {
            return true
        }
        // or we can trust the `expiration` of the user we stored.
        guard let user = user as? TestUser else {
            assert(false, "This application should use `TestUser` as the UserProtocol.")
            return true
        }
        guard let expiration = user.expiration else { return true }
        return expiration < Date()
    }
    
    func refreshAuthentication(with user: UserProtocol) -> Observable<UserProtocol> {
        return self.refreshToken().mapToUser()
    }
    
    func deauthenticate() -> ObservableSignal {
        return self.logout()
    }
}
``` 

After successfully refreshing, the `authState` will be set to `.authenticated`.

## Store 

Each `AppContext` has a `Store` inside, which provide storage features. Currently this function is built on `Realm` database which has `live object` and `thread-safe` features.

The `Store` provides three databases that are governed by different policies. 

```swift
public class Store {
    /// A database stored in `<root>/Library/Cache`, for data which want to keep for a while and unnecessary, may get deleted by system when disk free capicity is running low.
    public internal(set) var cache: RealmDataBase
    
    /// A database only in memory, reset after application process been killed.
    public internal(set) var memory: RealmDataBase
    
    /// A database stored in `<root>/Document`, for data which want to keep it until developer deleted it.
    public internal(set) var persistance: RealmDataBase
}
```

When any `Object` has changed, it is important to update the `StoreVersions`. For a more flexible design, the `StoreVersion` has separate schema versions for `.cache` and `.persistence`. However, many developers may use both to store their `Object`s. To improve usage convenience and flexibility, it is recommended to wrap the `StoreVersions` in a new class with a unique version.
