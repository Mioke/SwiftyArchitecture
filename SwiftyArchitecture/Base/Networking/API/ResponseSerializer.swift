//
//  ResponseSerializer.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2021/5/12.
//

import UIKit
import Alamofire
import ObjectMapper

public typealias DataResponse<T> = Alamofire.AFDataResponse<T>

public protocol ResponseSerializerProtocol  {
    associatedtype SerializedObject
    func serialize(data: DataResponse<Data>) throws -> SerializedObject
}

open class ResponseSerializer<SerializedObject>: NSObject, ResponseSerializerProtocol {
    public func serialize(data: DataResponse<Data>) throws -> SerializedObject {
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
            guard let item = item as? (key: Key, value: Value) else {
                return nil
            }
            return item
        })
    }
}

final public class JSONResponseSerializer<SerializedObject: JSONObject> : ResponseSerializer<SerializedObject> {
    
    public override func serialize(data: DataResponse<Data>) throws -> SerializedObject {
        if let resp = data.response, resp.statusCode != 200 {
            throw todo_error()
        }
        if let error = data.error {
            throw error
        }
        guard let data = data.data else { throw todo_error() }
        let result = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        
        if let value = result as? [AnyHashable: Any] {
            return try SerializedObject(jsonDictionary: value)
        } else if let value = result as? [Any] {
            return try SerializedObject(array: value)
        } else {
            throw todo_error()
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

/// A wrapper of new type `DecodableResponseSerializer` in Alamofire provided from 5.0
final public class JSONCodableResponseSerializer<SerializedObject: Decodable>: ResponseSerializer<SerializedObject> {
    public override func serialize(data: DataResponse<Data>) throws -> SerializedObject {
        let serializer = Alamofire.DecodableResponseSerializer<SerializedObject>()
        let result = try serializer.serialize(
            request: data.request,
            response: data.response,
            data: data.data,
            error: data.error)
        return result
    }
}

final public class JSONMappableResponseSerializer<T: Mappable>: ResponseSerializer<T> {
    public override func serialize(data: DataResponse<Data>) throws -> SerializedObject {
        if let resp = data.response, resp.statusCode != 200 {
            throw todo_error()
        }
        if let error = data.error {
            throw error
        }
        guard let data = data.data,
              let jsonString = String(data: data, encoding: .utf8),
              let result = T.init(JSONString: jsonString, context: nil)
        else {
            throw todo_error()
        }
        return result
    }
}

