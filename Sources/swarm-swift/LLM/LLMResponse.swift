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
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }

    public struct APIError: Codable {
        public let message: String
        public let type: String
        public let param: String?
        public let code: String?
    }
}
