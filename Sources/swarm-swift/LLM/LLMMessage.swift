//
//  LLMMessage.swift
//  
//
//  Created by Jingyuan Guo on 2024/10/21.
//

import Foundation

public struct LLMMessage: Codable {
    public var role: String
    public var content: String = ""
    public var additionalFields: [String: AnyCodable]?

    public init(role: String, content: String, additionalFields: [String: AnyCodable]? = nil) {
        self.role = role
        self.content = content
        self.additionalFields = additionalFields
    }

    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "role": role,
            "content": content
        ]
        additionalFields?.forEach { key, value in
            dict[key] = value.value
        }
        return dict
    }

    public func getValue(_ key: String) -> Any? {
        switch key {
        case "role":
            return role
        case "content":
            return content
        default:
            return additionalFields?[key]?.value
        }
    }

    // Implement Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(String.self, forKey: .role)
        do {
            content = try container.decode(String.self, forKey: .content)
        } catch {
                content = ""
        }
        additionalFields = try container.decodeIfPresent([String: AnyCodable].self, forKey: .additionalFields)
    }

    // Implement Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(additionalFields, forKey: .additionalFields)
    }

    private enum CodingKeys: String, CodingKey {
        case role, content, additionalFields
    }
}

// AnyCodable implementation
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let value as String:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as [String: AnyCodable]:
            try container.encode(value)
        case let value as [AnyCodable]:
            try container.encode(value)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}
