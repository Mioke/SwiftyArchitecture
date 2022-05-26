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

  Provide some basic functionality of a server like onlieURL, offlineURL, isOnline etc. In test Mode, offline the server. 
```swift
  #if DEBUG
    Server.online = false
  #endif
```

You can comstomize the operation of dealing response data now, just subclass from `Server` and conform to protocol `ServerDataProcessProtocol` like:
```swift
func handle(data: Any) throws -> Void {
    
    if  let dic = data as? [String: Any],
        let errorCode = dic["error_code"] as? Int,
        errorCode != 0 {
        throw NSError(domain: kYourErrorDomain, code: errorCode, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
```

- **API**

  Now you can manager request with `API<ApiInfoProtocol>`, creating a class conformed to `ApiInfoProtocol`, only need to provide some infomation about the API and set where the callback is, you are already finished the configuration of an API.  
  
```swift
    var apiVersion: String {
        get { return "v2" }
    }
    var apiName: String {
        get { return "user/login" }
    }
    var server: Server {
        get { return mainServer }
    }
    typealias ResultType = User
    static var responseSerializer: MIOSwiftyArchitecture.ResponseSerializer<User> {
        return MIOSwiftyArchitecture.JSONResponseSerializer<User>()
    }
```
  The API provide some basic method like:
  
```swift
  public func loadData(with params: [String: Any]?) -> Void
```

  Using chaining syntax to request data:
  ```swift
  api.loadData(with: nil).response({ (api, user, error) in
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
api.rx.loadData(with: params)
    .flatMap {
        ...
        return yourResultObservable
    }
    .bind(to: label.rx.text)
    .dispose(by: bag)
```
  
### Data Center

`SwiftyArchitecture` provides a data center, which can automatically manage your models, data and requests. This function is based on `Reactive Functional Programing`, and using `RxSwift`. The networking kit is using `API` and database is `Realm`.

It provides an accessor called `DataAccessObject<Object>`, and all data or models can be read throught this DAO.

Example:

Firstly, define your data model in model layer and your database model in `Realm`.

```swift
final class User: Codable {
    var userId: String = ""
    var name: String = ""
}

final class _User: Object {
    @objc dynamic var userId: String = ""
    @objc dynamic var name: String = ""
}
```

To manage this `User` model, it must be conform to protocol `DataCenterManaged`, this protocol defines how data center should do with this model.

```swift
extension User: DataCenterManaged {
    // defines how transform data from API to data base object.
    static func serialize(data: User) throws -> _User {
        let user = _User()
        user.name = data.name
        user.userId = data.userId
        return user
    }
    // define data base object's type
    typealias DatabaseObject = User
    // define API's type
    typealias APIInfo = UserAPI
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

let request = Request<User>()
DataAccessObject<User>
    .update(with: request)
    .subscribe({ event in
        switch event {
        case .completed:
            print("Hide loading")
        case .error(let error as NSError):
            print("Hide loading with error: \(error.localizedDescription)")
        default:
            break
        }
    })
    .disposed(by: self.disposeBag)
```

### Persistance (_refactoring_)

- **Database**  
 
  Like ApiManager, only need to subclass from `KMPersistanceDatabase` and conform to `DatabaseManagerProtocol`, provide `path`,`databaseName`,`database`, you are already create a new database in your project. e.g.

```swift
  class DefaultDatabase: KMPersistanceDatabase, DatabaseManagerProtocol {
    
    override init() {

        self.databaseName = "default.db"
        self.path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! + "/" + self.databaseName
        self.database = FMDatabaseQueue(path: self.path)
        
        super.init()
    }
  }
```

- **Table and Record**

  Subclass from `KMPersistanceTable` and conform to `TableProtocol` let you create a new table in a database. Any objcect conform `RecordProtocol` can be record in the table you want. See more details in demo.
  
  Using this just like:
  
```swift
    let table = UserTable()
    let newUser = UserModel(name: "Klein", uid: 310)
    table.replaceRecord(newUser)
```

- **Fetch**
  
  Fetch data with conditions using `DatabaseCommandCondition`:
```swift
    let table = UserTable()
    let condition = DatabaseCommandCondition()
            
    condition.whereConditions = "user_id >= 0"
    condition.orderBy = "user_name"
            
    let result = table.queryRecordWithSelect("user_name", condition: condition)
```

- **Advanced**

  Always, database provide method of doing query or execute with sql directly, for complex database operation:
```swift
  let db = DefaultDatabase()
  db.query("select * from tableDoesntExtist", withArgumentsInArray: nil)
```
  
### Modulize or Componentize

Support using `cocoapods` for modulize your project. You can separate some part of code which is indepence enough, and put the code into a `pod` repo. And finally the main project maybe have no code any more, when building your app, the `cocoapods` will install all the dependencies together and generate your app.

The good things of `modulization` or `componentization` are
- modules are closed between each other, and there's no way to visit the detail from another module; 
- modules can be used in other project, if the module is well designed; 
- instead of using git branch, now we can use version of the `pod` for development and generate app;
- using `cocoapods package` to generate binary library, fasten the app package process.

The bad things of it are (for now)
- low running performance for developing, because the more frameworks or libraries, the worse `lldb` performance get;
- need a lot of utils to maintain `pods` and their git repos, like auto generate version, auto update `Podfile` etc.

So, this function should depend on the situation of your team. `;)`

- **Module**

  Modules should register into the `ModuleManager` when app started.

  ```swift
  if let url = Bundle.main.url(forResource: "ModulesRegistery", withExtension: ".plist") {
      try! ModuleManager.default.registerModules(withConfigFilePath: url)
  }
  ```

  The registery `.plist` file contains an array of class names, which implement module's protocol, like:

  ```swift
  // in public protocol pod:
  public extension ModuleIdentifier {
      static let auth: ModuleIdentifier = "com.klein.module.auth"
  }

  public protocol AuthServiceProtocol {
      func authenticate(completion: @escaping (User) -> ()) throws
  }

  // in hidden pod:
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

- **Router**
  
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
- `SystemLog` can write log to files, and stored in sandbox.

> Almost done `>w<!`

# TODO

- [x] ~~Networking: ~~cache~~, origin data transform to Model or View's data, priority of request.~~ Done.
- [ ] Mock of API's response.
- [ ] Download and upload functions in API manager.
- [x] ~~Persistance: transform data to model or View's data after query.~~(don't need it now, using Realm)
- [x] ~~Animations, Tools and Kits: TextKit like [YYText](https://github.com/ibireme/YYText), etc~~. (SwiftyArchitecture won't provide those utilities, because base shouldn't have to.)
- [x] Refactoring, more functional and reative. Considering to use `Rx` or `ReactiveSwift`. Fully use genericity.
- [ ] Modulize of componentlization usage. Router.
  
# License
All the source code is published under the MIT license. See LICENSE file for details.
