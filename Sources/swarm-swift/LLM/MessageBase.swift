//
//  File.swift
//  
//
//  Created by Jingyuan Guo on 2024/10/24.
//

import Foundation
import SwiftyJSON

public class MessageBase
{
    public var json: JSON = JSON()
    
    public init() {
        
    }
    
    public init(data: Data, options opt: JSONSerialization.ReadingOptions = []) throws {
        let object: Any = try JSONSerialization.jsonObject(with: data, options: opt)
        self.json = JSON(object)
    }
    
    public init(parseJSON jsonString: String) {
        if let data = jsonString.data(using: .utf8) {
            self.json = JSON(data)
        } else {
            self.json = JSON(NSNull())
        }
    }
    
    public init(_ object: Any) {
        switch object {
        case let object as Data:
            do {
                try self.json = JSON(data: object)
            } catch {
                self.json = JSON(NSNull())
            }
        default:
            self.json = JSON(object)
        }
    }
    
    public func getString(key: String) ->String{
        return json[key].stringValue
    }
    
    public func setString(forKey key:String, value:String) {
        json[key] = JSON(value)
    }
    
    public func getString(keyPath: [JSONSubscriptType]) ->String{
        return json[keyPath].stringValue
    }
    
    public func rawData(options opt: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions(rawValue: 0)) throws -> Data{
        return try json.rawData()
    }
}
