//
//  ResponseSerializer.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2021/5/12.
//

import UIKit
import Alamofire

public protocol ResponseSerializerProtocol  {
    associatedtype SerializedObject
    func serialize(data: Alamofire.DataResponse<Data>) throws -> SerializedObject
}

open class ResponseSerializer<SerializedObject>: NSObject, ResponseSerializerProtocol {
    public func serialize(data: Alamofire.DataResponse<Data>) throws -> SerializedObject {
        throw todo_error()
    }
}

extension ResponseSerializerProtocol where SerializedObject: ApiInfoProtocol {
    public var api: API<SerializedObject> {
        return API<SerializedObject>()
    }
}

public protocol JSONObject {
    init(jsonDictionary dictionary: [AnyHashable: Any]) throws
    init(array: [Any]) throws
}

extension JSONObject {
    public init(jsonDictionary dictionary: [AnyHashable: Any]) throws {
        let message = "\(String(describing: type(of: Self.self))) doesn't support to initialize from a dictionary"
        throw NSError(domain: "", code: 777, userInfo: [NSLocalizedDescriptionKey: message])
    }

    public init(array: [Any]) throws {
        let message = "\(String(describing: type(of: Self.self))) doesn't support to initialize from an array"
        throw NSError(domain: "", code: 777, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

extension Dictionary: JSONObject {
    public init(jsonDictionary dictionary: [AnyHashable : Any]) throws {
        self.init(uniqueKeysWithValues: dictionary.compactMap { (item) -> (key: Key, value: Value)? in
            guard let key = item.key as? Key, let value = item.value as? Value else {
                return nil
            }
            return (key: key, value: value)
        })
    }
}

final public class JSONResponseSerializer<SerializedObject: JSONObject> : ResponseSerializer<SerializedObject> {
    
    public override func serialize(data: DataResponse<Data>) throws -> SerializedObject {
        let result = Alamofire.Request.serializeResponseJSON(
            options: JSONSerialization.ReadingOptions.allowFragments,
            response: data.response,
            data: data.data,
            error: data.error)
        
        switch result {
        case .success(let value):
            if let value = value as? [AnyHashable: Any] {
                return try SerializedObject(jsonDictionary: value)
            } else if let value = value as? [Any] {
                return try SerializedObject(array: value)
            } else {
                throw todo_error()
            }
        case .failure(let error):
            throw error
        }
    }
}

public protocol DataObject {
    init(data: Data?) throws
}

final public class DataResponseSerializer<SerializedObject: DataObject> : ResponseSerializer<SerializedObject> {
    public override func serialize(data: DataResponse<Data>) throws -> SerializedObject {
        return try SerializedObject(data: data.data)
    }
}

open class ProtocResponseSerializer<SerializedObject>: ResponseSerializer<SerializedObject> {
    
    public override func serialize(data: DataResponse<Data>) throws -> SerializedObject {
        throw todo_error()
    }
}

final public class JSONCodableResponseSerializer<SerializedObject: Decodable>: ResponseSerializer<SerializedObject> {
    public override func serialize(data: DataResponse<Data>) throws -> SerializedObject {
        if let error = data.error {
            throw error
        }
        guard let data = data.data else {
            throw todo_error()
        }
        let decoder = JSONDecoder()
        return try decoder.decode(SerializedObject.self, from: data)
    }
}
