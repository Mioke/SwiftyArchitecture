# SwiftArchitectureWithPOP
A base architecture written in swift and protocol oriented. 

### Installation
##### Using cocoapods:
```ruby
pod 'SwiftyArchitecture'
# or choose on your need
pod 'SwiftyArchitecture/Persistance'
pod 'SwiftyArchitecture/Networking'
pod 'SwiftyArchitecture/RxExtension'
# Write tests
pod 'SwiftyArchitecture/Testable'
```
##### Manually
Download `.zip` package and copy the `SwiftyArchitecture/Base` folder into you project.

### What to provide

- Networking.
- Persistence.
- Data center, handle all API and storage of response data in realm database.
- Modulize or componentize your main project, provide data transmit and router between modules.
- Reactive extension for all functionalities above.
  
### Networking

- **Server**

  Provide some basic functionalities of a server like url configuation, environments switch etc. In test Mode, offline the server. 
```swift
  let server: Server = .init(live: cdn.config.liveURL,
                             customEnvironments: [
                              .custom("Dev"): cdn.config.devURL,
                              .custom("Staging"): cdn.config.stagingURL,
                            ])
  #if DEBUG
      server.switch(to: .custom("Dev"))
  #endif
```

You can comstomize the operation of dealing response data now, just subclass from `Server` and conform to protocol `ServerDataProcessProtocol` like:
```swift
func handle(data: Any) throws -> Void {
    
    if let dic = data as? [String: Any],
       let errorCode = dic["error_code"] as? Int,
       errorCode != 0 {
        throw NSError(domain: kYourErrorDomain, 
                      code: errorCode, 
                      userInfo: [NSLocalizedDescriptionKey: message])
    }
}
```

- **API**

  Now you can manager request with `API<ApiInfoProtocol>`, creating a class conformed to `ApiInfoProtocol`, only need to provide some infomation about the API and set where the callback is, you are already finished the configuration of an API.  
  
```swift
    typealias RequestParam = [String, Any]
    
    var apiVersion: String {
        get { return "v2" }
    }
    var apiName: String {
        get { return "user/login" }
    }
    var server: Server {
        get { return mainServer }
    }

    typealias ResultType = _User

    static var responseSerializer: ResponseSerializer<ResultType> {
        return JSONResponseSerializer<ResultType>()
    }
```
  The API provide some basic method like:
  
```swift
  public func sendRequest(with params: [String: Any]?) -> Void
```

  Using chaining syntax to request data:
  ```swift
  api.sendRequest(with: nil).response({ (api, user, error) in
    if let error = error {
      // deal error
    }
    if let user = user {
      // do response if have data
    }
  })
  ```

  - **Rx supported**

ApiManager provides an `Observable` for you, you can transfrom it or directly bind it to something:

```swift
api.rx.sendRequest(with: params)
    .flatMap {
        ...
        return yourResultObservable
    }
    .bind(to: label.rx.text)
    .dispose(by: bag)
```

### App Dock
See [this documentation](https://github.com/Mioke/SwiftyArchitecture/blob/dev/README-AppDocker.md) for detail, include `App Context` & `User Context` & `Store`.
  
### Data Center

`SwiftyArchitecture` provides a data center, which can automatically manage your models, data and requests. This function is based on `Reactive Functional Programing`, and using `RxSwift`. The networking kit is using `API` and database is `Realm`.

It provides an accessor called `DataAccessObject<Object>`, and all data or models can be read throught this DAO.

Example:

Firstly, define your data model in model layer and your database model in `Realm`.

```swift
class User: RealmSwift.Object {
    @Persisted(primaryKey: true)
    var userId: String = ""
    @Persisted
    var name: String = ""
}
```

Then there may have a API which request data relevant to the `User` model:
```swift
final class UserAPI: ApiInfoProtocol {
    struct Param: Codable {
        let uids: [String]
    }
    typealias RequestParam = UserAPI.Param
    
    struct Reply: Codable {
        struct User: Codable {
            var userId: String
            var name: String
            var version: String?
        }
        var users: [Reply.User]
    }
    typealias ResultType = Reply
    
    static var apiVersion: String {
        get { return "v1" }
    }
    static var apiName: String {
        get { return "getUserInfo" }
    }
    static var server: Server {
        get { return getServer() }
    }
    static var httpMethod: Alamofire.HTTPMethod {
        get { return .get }
    }
    static var responseSerializer: ResponseSerializer<Reply> {
        return JSONCodableResponseSerializer<Reply>()
    }
}
```

To manage this `User` model, it must be conformed to the protocol `DataCenterManaged`, this protocol defines how data center should do with this model.

```swift
extension User: DataCenterManaged {
    // define API's type
    typealias APIInfo = UserAPI
    
    // defines how transform data from API to data base object.
    static func serialize(data: UserAPI.Reply) throws -> [RealmSwift.Object] {
        let result: [Object] = data.users.map { item in
            let user = User()
            user.name = item.name
            user.userId = item.userId
            return user
        }
        if data.isFinal {
            // do something else
        }
        return result
    }
}
```

Then you can read the data in database and use it by using `DataAccessObject<User>`.

```swift
// read all users and display on table view.
DataAccessObject<User>.all
    .map { $0.sorted(by: <) }
    .map { [AnimatableSectionModel(model: "", items: $0)] }
    .bind(to: tableView.rx.items(dataSource: datasource))
    .disposed(by: disposeBag)
```

And then you can update models throught requests, and when data changed, the `Observable<User>` will notify observers the new model is coming. And data center will save the newest data to database. For developers of in feature team, they should only need to forcus on models and actions. 

```swift
print("Show loading")

let request: Request<User> = .init(params: .init(uids: ["10025"]))
DataCenter.update(with: request)
    .subscribe({ event in
        switch event {
        case .completed:
            print("Hide loading")
        case .error(let error as NSError):
            print("Hide loading with error: \(error.localizedDescription)")
        }
    })
    .disposed(by: self.disposeBag)
```
  
### Modulize or Componentize

Support using `cocoapods` to modulize your project. You can separate some part of code which is indepence enough, and put the code into a `pod` repo. And finally the main project maybe have no code any more, when building your app, the `cocoapods` will install all the dependencies together and generate your app.

The good things of `modulization` or `componentization` are
- modules are closed between each other, and there's no way to visit the detail from another module; 
- modules can be used in other project, if the module is well designed; 
- instead of using git branch, now we can use version of the `pod` for development and generate app;
- using `cocoapods package` to generate binary library, fasten the app package process.

The bad things of it are (for now)
- low running performance for developing, because the more frameworks or libraries, the worse DYLD performance get;
- need a lot of utils to maintain `pods` and their git repos, like auto generate version, auto update `Podfile` etc.

So, this function should depend on the situation of your team and your project. `;)`

For small-sized teams, I would like to recommend the `monorepo` format for your components. This means you can place all your components in one Git repository but in different folders and create a `.podspec` for each of them. Then, you can manage them using Git branches instead of publishing them one by one. At the same time, all the code is separated by Cocoapods, which cannot access each other between pods.

For large-sized teams, if you have a chain of tools and utilities to build pods and publish them, and have an integration tool to put them together into a main project, then you can use the `multi-repo` format to manage your pods.

- **Module**

  Modules should register into the `ModuleManager` when app started.

  ```swift
  if let url = Bundle.main.url(forResource: "ModulesRegistery", withExtension: ".plist") {
      try! ModuleManager.default.registerModules(withConfigFilePath: url)
  }
  ```

  The register `.plist` file contains an array of class names, which implement module's protocol, like:

  ```swift
  // in public protocol pod:
  public extension ModuleIdentifier {
      static let auth: ModuleIdentifier = "com.klein.module.auth"
  }

  public protocol AuthServiceProtocol {
      func authenticate(completion: @escaping (User) -> ()) throws
  }

  // in private pod:
  class AuthModule: ModuleProtocol, AuthServiceProtocol {
      static var moduleIdentifier: ModuleIdentifier {
          return .auth
      }
      required init() { }
      
      func moduleDidLoad(with manager: ModuleManager) {}
      
      func authenticate(completion: @escaping (User) -> ()) throws {
          // do your work
      }
  }

  // in .plist
  array:
    Auth.AuthModule,
    ...
  ```
    
  Call other module's method like

  ```swift
  guard let authModule = try? self.moduleManager?.bridge.resolve(.auth) as? AuthServiceProtocol 
  else {
      fatalError()
  }
  authModule.authenticate(completion: { user in
      print(user)
  })
  ```

- **Navigation**
  
  TBA

- **Initiator**

  When some modules should do some work at the start process, you will need `Initiator` and regitster you opartion in it.

  ```swift
  // defined in framework
  public protocol ModuleInitiatorProtocol {
      static var identifier: String { get }
      static var operation: Initiator.Operation { get }
      static var priority: Initiator.Priority { get }
      static var dependencies: [String] { get }
  }

  // implement in pod repo
  extension AuthModule: ModuleInitiatorProtocol {
      static var identifier: String { moduleIdentifier }
      static var priority: Initiator.Priority { .high }
      static var dependencies: [String] { [ModuleIdentifier.application] }
      static var operation: Initiator.Operation {
          return {
              // do something
          }
      }
  }  
  ```

### Tools and Kits

- Custom extensions and categories.
- UI relevant class for easy accessing global UI settings.
- Logger API, default to write in system console, you can customize the action and record messages somewhere else.

> Almost done `>w<!`

# TODO

- [x] Networking: cache, origin data transform to Model or View's data, priority of request.
- [x] Mock of API's response.
- [ ] Download and upload functions in API manager.
- [x] ~~Persistance: transform data to model or View's data after query.~~(don't need it now, using Realm)
- [x] ~~Animations, Tools and Kits: TextKit like [YYText](https://github.com/ibireme/YYText), etc~~. (SwiftyArchitecture won't provide those utilities, because base shouldn't have to.)
- [x] Refactoring, more functional and reative. Considering to use `Rx` or `ReactiveSwift`. Fully use genericity.
- [x] Modulize of componentization usage. Router.
  
# License
All the source code is published under the MIT license. See LICENSE file for details.
