# SwiftArchitectureWithPOP
A base architecture written by swift and protocol oriented. Created by Klein Mioke.

### What to provide

#### Task
- **Task executor and result reciever.**

  Any Object can be a task executor or a result reciever by conform the protocols of `sender` and `reciever`. A task can be any operation that you want be done in background thread. And callbacks will running in main thread again to do the things later.
  
  ```swift
  // self is any thing conform to protocol<sender, reciever>
  
  func someAction() -> Void {
      self.doTask({ () -> receiveDataType in
          return someCalculationNeedLongTime()
      }, identifier: "calculation")
  }
  
  // callback
  override func finishTaskWithReuslt(result: receiveDataType, identifier: String) {
       if identifier == "calculation" {
          Log.debugPrint(result)
      }
  }
    
  override func taskCancelledWithError(error: ErrorResultType, identifier: String) {
      super.taskCancelledWithError(error, identifier: identifier)
  }
  ```
  
#### Networking

- **Server**

  Provide some basic functionality of a server like onlieURL, offlineURL, isOnline etc. In test Mode, offline the server. 
  ```swift
  #if DEBUG
    Server.online = false
  #endif
  ```

- **ApiManager**

  Now you can manager request with `ApiManager`, just sublass from `BaseApiManager` and conform to protocol `ApiInfoProtocol`. Only need to provide some infomation about the API and set where the callback is, you are already finished the configuration of an API.
  
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
  ```
  The BaseApiManager provide some basic method like:
  
  ```swift
  func loadDataWithParams(params: [String: AnyObject]) -> Void
  ```
  
  Setting delegate for receiving origin data:
  
  ```swift
  extension ViewController: ApiCallbackProtocol {
    
      func ApiManager(apiManager: BaseApiManager, finishWithOriginData data: AnyObject) {
        
          if let apiManager = apiManager as? ApiLogin {
              print("login success: \n \(apiManager.originData())")
          }
      }
    
      func ApiManager(apimanager: BaseApiManager, failedWithError error: NSError) {
          
          if apiManager is ApiLogin {
              Log.debugPrint("login failed with error: \(error)")
          }
      }
  }
  ```
- **Attentions**
  
  1. The request is generated by `KMRequestGenerator`, using [Alamofire](https://github.com/Alamofire/Alamofire) Request. 
  2. Customize your own way about "tell the request is succeed or not" in `BaseApiManager`, when your server returns error code or error message. And writing general solution in `NetworkManager.dealError(error: ErrorType)`

#### Persistance

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
            
    let result = table.queryRecordWithSelect(nil, condition: condition)
  ```

- **Advanced**

  Always, database provide method of doing query or execute with sql directly, for complex database operation:
  ```swift
  let db = DefaultDatabase()
  db.query("select * from tableDoesntExtist", withArgumentsInArray: nil)
  ```
  
#### Tools and Kits

- Using CocoaPods
- Custom extensions and categories

> Not done yet~~~

# TODO

- Networking: ~~cache~~, origin data transform to Model or View's data, priority of request.
- Persistance: transform data to model or View's data after query.
- Animations
- Tools and Kits: TextKit like [YYText](https://github.com/ibireme/YYText), etc.
  
#License
All the source code is published under the MIT license. See LICENSE file for details.
