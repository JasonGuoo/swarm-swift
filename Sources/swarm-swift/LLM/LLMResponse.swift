import Foundation

public struct LLMResponse: Codable {
    public var id: String?
    public var object: String?
    public var created: Int?
    public var model: String?
    public var choices: [Choice]?
    public var usage: Usage?
    public var systemFingerprint: String?
    public var error: APIError?

    public struct Choice: Codable {
        public var index: Int?
        public var message: LLMMessage?
        public var finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }

    public struct ToolCall: Codable {
        public var id: String?
        public var type: String?
        public var function: FunctionCall?
    }

    public struct FunctionCall: Codable {
        public var name: String?
        public var arguments: String?
    }

    public struct Usage: Codable {
        public var promptTokens: Int?
        public var completionTokens: Int?
        public var totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }

    public struct APIError: Codable {
        public var message: String?
        public var type: String?
        public var param: String?
        public var code: String?
    }
    
    public var description: String {
        var desc = "LLMResponse:\n"
        if let id = id { desc += "  ID: \(id)\n" }
        if let object = object { desc += "  Object: \(object)\n" }
        if let created = created { desc += "  Created: \(created)\n" }
        if let model = model { desc += "  Model: \(model)\n" }
        if let choices = choices {
            desc += "  Choices:\n"
            for choice in choices {
                if let index = choice.index { desc += "    Index: \(index)\n" }
                if let message = choice.message {
                    if let dict = try? message.toDictionary() {
                        desc += "    Message: \(dict)\n"
                    }
                }
                if let finishReason = choice.finishReason {
                    desc += "    Finish Reason: \(finishReason)\n"
                }
            }
        }
        if let usage = usage {
            desc += "  Usage:\n"
            if let promptTokens = usage.promptTokens { desc += "    Prompt Tokens: \(promptTokens)\n" }
            if let completionTokens = usage.completionTokens { desc += "    Completion Tokens: \(completionTokens)\n" }
            if let totalTokens = usage.totalTokens { desc += "    Total Tokens: \(totalTokens)\n" }
        }
        if let systemFingerprint = systemFingerprint {
            desc += "  System Fingerprint: \(systemFingerprint)\n"
        }
        if let error = error {
            desc += "  Error:\n"
            if let message = error.message { desc += "    Message: \(message)\n" }
            if let type = error.type { desc += "    Type: \(type)\n" }
            if let param = error.param { desc += "    Param: \(param)\n" }
            if let code = error.code { desc += "    Code: \(code)\n" }
        }
        return desc
    }

    public static func fromJSON(_ jsonString: String) -> Result<LLMResponse, Error> {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return .failure(NSError(domain: "LLMResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string"]))
        }
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(LLMResponse.self, from: jsonData)
            return .success(response)
        } catch {
            return .failure(error)
        }
    }
    
    public var isEmpty: Bool {
        return id == nil && object == nil && created == nil && model == nil && choices?.isEmpty != false && usage == nil && systemFingerprint == nil && error == nil
    }
}
