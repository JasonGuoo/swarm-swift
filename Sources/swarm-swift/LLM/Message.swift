//
//  LLMMessage.swift
//  
//
//  Created by Jingyuan Guo on 2024/10/21.
//

import Foundation
import SwiftyJSON

public class Message: MessageBase, CustomStringConvertible {
    
    public override init() {
        super.init()
    }
    
    public func role() -> String {
        return getString(key: "role")
    }
    
    public func content() -> String {
        return getString(key: "content")
    }
    
    public func withRole(role: String) -> Message {
        setString(forKey: "role", value: role)
        return self
    }
    
    public func withContent(content: String) -> Message {
        setString(forKey: "content", value: content)
        return self
    }
    
    public func withToolCallId(_ id: String) -> Message {
        setString(forKey: "tool_call_id", value: id)
        return self
    }
    
    public func withToolName(_ name: String) -> Message {
        setString(forKey: "tool_name", value: name)
        return self
    }
    
    public func toolCallId() -> String {
        return getString(key: "tool_call_id")
    }
    
    public func toolName() -> String {
        return getString(key: "tool_name")
    }
    
    public required init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.singleValueContainer()
        json = try container.decode(JSON.self)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(json)
    }
    
    public init(_ json: JSON) {
        super.init()
        self.json = json
    }
    
    public var description: String {
        let options: JSONSerialization.WritingOptions = [.prettyPrinted]
        if let jsonData = try? JSONSerialization.data(withJSONObject: json.object, options: options),
           let prettyPrintedString = String(data: jsonData, encoding: .utf8) {
            return prettyPrintedString
        }
        return json.description // Fallback to default description if beautification fails
    }
}

public struct MessageCodable: Codable {
    let json: JSON
    
    public init(_ json: JSON) {
        self.json = json
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let jsonData = try container.decode(Data.self)
        json = try JSON(data: jsonData)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(json.rawData())
    }
}
