//
//  APITests.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/5/30.
//

import Foundation
@testable import MIOSwiftyArchitecture
import XCTest
import RxSwift
import Alamofire

class APITests: XCTestCase {
    
    var cancel: DisposeBag = .init()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    let testApi = API<UserAPI>()
    
    func testMock() {
        APIMocker.mock(type: UserAPI.self) { params in
            return User(userId: "1", name: "Klein")
        }
        
        let expect = XCTestExpectation(description: "Api test mock")
        
        testApi.rxLoadData(with: ["id": "1"])
            .subscribe { event in
                print(event)
                guard case .next(_) = event else { return }
                expect.fulfill()
            }
            .disposed(by: cancel)
        
        wait(for: [expect], timeout: 1)
    }
    
    func testRemoveMock() {
        APIMocker.recover(type: UserAPI.self)
        
        let expect = XCTestExpectation(description: "RemoveMock")
        testApi.rxLoadData(with: ["id": "1"])
            .subscribe { event in
                print(event)
                guard case .error(_) = event else { return }
                expect.fulfill()
            }
            .disposed(by: cancel)
        wait(for: [expect], timeout: 5)
    }
}

struct User: Codable {
    var userId: String
    var name: String
}

let MioDemoServer: Server = .init(live: URL(string: "https://www.baidu.com")!,
                                  customEnvironments: [
                                    .custom("Dev"): URL(string: "https://www.baidu.com")!,
                                    .custom("Staging"): URL(string: "https://www.baidu.com")!,
                                  ])

final class UserAPI: NSObject, ApiInfoProtocol {
    
    typealias ResultType = User
    
    static var apiVersion: String {
        get { return "" }
    }
    static var apiName: String {
        get { return "s" }
    }
    static var server: Server {
        get { return MioDemoServer }
    }
    static var httpMethod: Alamofire.HTTPMethod {
        get { return .get }
    }
    
    static var responseSerializer: MIOSwiftyArchitecture.ResponseSerializer<User> {
        return MIOSwiftyArchitecture.JSONCodableResponseSerializer<User>()
    }
}
