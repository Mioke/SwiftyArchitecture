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

/// Placeholder for ProtocBuffer.
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

/// A serializer for models conformed to `Mappable`.
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

