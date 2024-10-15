import Foundation

public struct LLMResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage?
    public let systemFingerprint: String?
    public let error: APIError?

    public struct Choice: Codable {
        public let index: Int
        public let message: LLMRequest.Message
        public let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }

    public struct Usage: Codable {
        public let promptTokens: Int?
        public let completionTokens: Int?
        public let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }

    public struct APIError: Codable {
        public let message: String?
        public let type: String?
        public let param: String?
        public let code: String?
    }
    
    public var description: String {
        var desc = "LLMResponse:\n"
        desc += "  ID: \(id)\n"
        desc += "  Object: \(object)\n"
        desc += "  Created: \(created)\n"
        desc += "  Model: \(model)\n"
        desc += "  Choices:\n"
        for choice in choices {
            desc += "    Index: \(choice.index)\n"
            desc += "    Message: Role: \(choice.message.role), Content: \(choice.message.content)\n"
            if let finishReason = choice.finishReason {
                desc += "    Finish Reason: \(finishReason)\n"
            }
        }
        if let usage = usage {
            desc += "  Usage:\n"
            desc += "    Prompt Tokens: \(usage.promptTokens)\n"
            desc += "    Completion Tokens: \(usage.completionTokens)\n"
            desc += "    Total Tokens: \(usage.totalTokens)\n"
        }
        if let systemFingerprint = systemFingerprint {
            desc += "  System Fingerprint: \(systemFingerprint)\n"
        }
        if let error = error {
            desc += "  Error:\n"
            desc += "    Message: \(error.message)\n"
            desc += "    Type: \(error.type)\n"
            if let param = error.param {
                desc += "    Param: \(param)\n"
            }
            if let code = error.code {
                desc += "    Code: \(code)\n"
            }
        }
        return desc
    }
}
