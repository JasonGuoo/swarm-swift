import Foundation

public struct LLMRequest: Codable {
    public let model: String
    public let messages: [Message]
    public let temperature: Double?
    public let topP: Double?
    public let n: Int?
    public let stream: Bool?
    public let stop: [String]?
    public let maxTokens: Int?
    public let presencePenalty: Double?
    public let frequencyPenalty: Double?
    public let logitBias: [String: Int]?
    public let user: String?
    public let voice: String?
    public let responseFormat: String?
    public let speed: Double?
    public let fileData: Data?
    public let fileName: String?
    public let language: String?

    public struct Message: Codable {
        public let role: String
        public let content: String
        public let name: String?

        public init(role: String, content: String, name: String? = nil) {
            self.role = role
            self.content = content
            self.name = name
        }
    }

    public init(
        model: String,
        messages: [Message],
        temperature: Double? = nil,
        topP: Double? = nil,
        n: Int? = nil,
        stream: Bool? = nil,
        stop: [String]? = nil,
        maxTokens: Int? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        logitBias: [String: Int]? = nil,
        user: String? = nil,
        voice: String? = nil,
        responseFormat: String? = nil,
        speed: Double? = nil,
        fileData: Data? = nil,
        fileName: String? = nil,
        language: String? = nil
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.topP = topP
        self.n = n
        self.stream = stream
        self.stop = stop
        self.maxTokens = maxTokens
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.logitBias = logitBias
        self.user = user
        self.voice = voice
        self.responseFormat = responseFormat
        self.speed = speed
        self.fileData = fileData
        self.fileName = fileName
        self.language = language
    }
}
