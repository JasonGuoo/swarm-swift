import Foundation

public struct LLMRequest: Codable {
    public static let defaultMaxTokens = 8092
    public static let defaultTemperature = 0.7
    public static let defaultTopP = 1.0
    public static let defaultFrequencyPenalty = 0.0
    public static let defaultPresencePenalty = 0.0
    public static let defaultStop: [String] = []

    public var model: String
    public var messages: [Message]
    public var temperature: Double?
    public var topP: Double?
    public var n: Int?
    public var stream: Bool?
    public var stop: [String]?
    public var maxTokens: Int?
    public var presencePenalty: Double?
    public var frequencyPenalty: Double?
    public var logitBias: [String: Int]?
    public var user: String?
    public var voice: String?
    public var responseFormat: String?
    public var speed: Double?
    public var fileData: Data?
    public var fileName: String?
    public var language: String?
    public var tools: [Tool]?
    public var toolChoice: String?

    public struct Message: Codable {
        public var role: String
        public var content: String?
        public var name: String?

        public init(role: String, content: String? = nil, name: String? = nil) {
            self.role = role
            self.content = content
            self.name = name
        }
    }

    public struct Tool: Codable {
        public var type: String
        public var function: Function
    }

    public struct Function: Codable {
        public var name: String
        public var description: String
        public var parameters: Parameters
    }

    public struct Parameters: Codable {
        public var type: String
        public var properties: [String: Property]
        public var required: [String]
    }

    public struct Property: Codable {
        public var type: String
        public var description: String?
        public var enums: [String]?
    }

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case topP = "top_p"
        case n
        case stream
        case stop
        case maxTokens = "max_tokens"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case logitBias = "logit_bias"
        case user
        case voice
        case responseFormat = "response_format"
        case speed
        case fileData = "file_data"
        case fileName = "file_name"
        case language
        case tools
        case toolChoice = "tool_choice"
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
        language: String? = nil,
        tools: [Tool]? = nil,
        toolChoice: String? = nil
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
        self.tools = tools
        self.toolChoice = toolChoice
    }
    
    public var description: String {
        var desc = "LLMRequest:\n"
        desc += "  Model: \(model)\n"
        desc += "  Messages:\n"
        for message in messages {
            desc += "    Role: \(message.role), Content: \(message.content ?? ""), Name: \(message.name ?? "")\n"
        }
        if let temperature = temperature { desc += "  Temperature: \(temperature)\n" }
        if let topP = topP { desc += "  Top P: \(topP)\n" }
        if let n = n { desc += "  N: \(n)\n" }
        if let stream = stream { desc += "  Stream: \(stream)\n" }
        if let stop = stop { desc += "  Stop: \(stop)\n" }
        if let maxTokens = maxTokens { desc += "  Max Tokens: \(maxTokens)\n" }
        if let presencePenalty = presencePenalty { desc += "  Presence Penalty: \(presencePenalty)\n" }
        if let frequencyPenalty = frequencyPenalty { desc += "  Frequency Penalty: \(frequencyPenalty)\n" }
        if let logitBias = logitBias { desc += "  Logit Bias: \(logitBias)\n" }
        if let user = user { desc += "  User: \(user)\n" }
        if let voice = voice { desc += "  Voice: \(voice)\n" }
        if let responseFormat = responseFormat { desc += "  Response Format: \(responseFormat)\n" }
        if let speed = speed { desc += "  Speed: \(speed)\n" }
        if fileData != nil { desc += "  File Data: [Data]\n" }
        if let fileName = fileName { desc += "  File Name: \(fileName)\n" }
        if let language = language { desc += "  Language: \(language)\n" }
        if let tools = tools {
            desc += "  Tools:\n"
            for tool in tools {
                desc += "    Type: \(tool.type)\n"
                desc += "    Function:\n"
                desc += "      Name: \(tool.function.name)\n"
                desc += "      Description: \(tool.function.description)\n"
                desc += "      Parameters:\n"
                desc += "        Type: \(tool.function.parameters.type)\n"
                desc += "        Properties:\n"
                for (key, property) in tool.function.parameters.properties {
                    desc += "          \(key):\n"
                    desc += "            Type: \(property.type)\n"
                    if let description = property.description {
                        desc += "            Description: \(description)\n"
                    }
                    if let enumValues = property.enums {
                        desc += "            Enum: \(enumValues)\n"
                    }
                }
                desc += "        Required: \(tool.function.parameters.required)\n"
            }
        }
        if let toolChoice = toolChoice {
            desc += "  Tool Choice: \(toolChoice)\n"
        }
        return desc
    }

    /// Creates an LLMRequest instance with the given parameters.
    ///
    /// - Parameters:
    ///   - model: The name of the model to use for the request.
    ///   - messages: An array of dictionaries representing the conversation history.
    ///               Each dictionary should have a single key-value pair where the key is the role
    ///               (e.g., "system", "user", "assistant") and the value is the message content.
    ///   - temperature: Controls randomness in the model's output. Default is 0.7.
    ///   - maxTokens: The maximum number of tokens to generate. Default is LLMRequest.defaultMaxTokens.
    ///   - stream: Whether to stream the response. Default is false.
    ///   - additionalParameters: A dictionary of additional parameters to include in the request.
    ///
    /// - Returns: An LLMRequest instance configured with the provided parameters.
    ///
    /// - Example:
    ///   ```swift
    ///   let request = LLMRequest.create(
    ///       model: "gpt-3.5-turbo",
    ///       messages: [
    ///           ["system": "You are a helpful assistant."],
    ///           ["user": "What's the weather like today?"]
    ///       ],
    ///       temperature: 0.8,
    ///       additionalParameters: ["top_p": 0.9, "user": "user123"]
    ///   )
    ///   ```
    public static func create(
        model: String,
        messages: [[String: String]],
        temperature: Double = 0.7,
        maxTokens: Int = LLMRequest.defaultMaxTokens,
        stream: Bool = false,
        additionalParameters: [String: Any] = [:],
        tools: [Tool]? = nil,
        toolChoice: String? = nil
    ) -> LLMRequest {
        let formattedMessages = messages.map { dict -> Message in
            let role = dict.keys.first ?? "user"
            let content = dict[role] ?? ""
            return Message(role: role, content: content)
        }
        
        var request = LLMRequest(
            model: model,
            messages: formattedMessages,
            temperature: temperature,
            stream: stream,
            maxTokens: maxTokens,
            tools: tools,
            toolChoice: toolChoice
        )
        
        // Apply additional parameters
        for (key, value) in additionalParameters {
            switch key {
            case "topP": request.topP = value as? Double
            case "n": request.n = value as? Int
            case "stop": request.stop = value as? [String]
            case "presencePenalty": request.presencePenalty = value as? Double
            case "frequencyPenalty": request.frequencyPenalty = value as? Double
            case "logitBias": request.logitBias = value as? [String: Int]
            case "user": request.user = value as? String
            case "voice": request.voice = value as? String
            case "responseFormat": request.responseFormat = value as? String
            case "speed": request.speed = value as? Double
            case "fileData": request.fileData = value as? Data
            case "fileName": request.fileName = value as? String
            case "language": request.language = value as? String
            default: break
            }
        }
        
        return request
    }

    /// Creates an LLMRequest instance from a JSON dictionary.
    ///
    /// - Parameter json: A dictionary representing the JSON data for the request.
    ///
    /// - Returns: An LLMRequest instance configured with the provided JSON data.
    ///
    /// - Throws: LLMRequestError.missingRequiredField if required fields are missing from the JSON.
    ///
    /// - Example:
    ///   ```swift
    ///   let jsonData: [String: Any] = [
    ///       "model": "gpt-3.5-turbo",
    ///       "messages": [
    ///           ["system": "You are a helpful assistant."],
    ///           ["user": "What's the capital of France?"]
    ///       ],
    ///       "temperature": 0.7,
    ///       "max_tokens": 1000,
    ///       "stream": false
    ///   ]
    ///
    ///   do {
    ///       let request = try LLMRequest.fromJSON(jsonData)
    ///       print(request.description)
    ///   } catch {
    ///       print("Error creating LLMRequest: \(error)")
    ///   }
    ///   ```
    public static func fromJSON(_ json: [String: Any]) throws -> LLMRequest {
        guard let model = json["model"] as? String else {
            throw LLMRequestError.missingRequiredField("model")
        }
        
        guard let messagesArray = json["messages"] as? [[String: String]] else {
            throw LLMRequestError.missingRequiredField("messages")
        }
        
        let messages = messagesArray.map { dict -> Message in
            let role = dict.keys.first ?? "user"
            let content = dict[role] ?? ""
            return Message(role: role, content: content)
        }
        
        var request = LLMRequest(model: model, messages: messages)
        
        if let temperature = json["temperature"] as? Double {
            request.temperature = temperature
        }
        if let topP = json["top_p"] as? Double {
            request.topP = topP
        }
        if let n = json["n"] as? Int {
            request.n = n
        }
        if let stream = json["stream"] as? Bool {
            request.stream = stream
        }
        if let stop = json["stop"] as? [String] {
            request.stop = stop
        }
        if let maxTokens = json["max_tokens"] as? Int {
            request.maxTokens = maxTokens
        }
        if let presencePenalty = json["presence_penalty"] as? Double {
            request.presencePenalty = presencePenalty
        }
        if let frequencyPenalty = json["frequency_penalty"] as? Double {
            request.frequencyPenalty = frequencyPenalty
        }
        if let logitBias = json["logit_bias"] as? [String: Int] {
            request.logitBias = logitBias
        }
        if let user = json["user"] as? String {
            request.user = user
        }
        if let voice = json["voice"] as? String {
            request.voice = voice
        }
        if let responseFormat = json["response_format"] as? String {
            request.responseFormat = responseFormat
        }
        if let speed = json["speed"] as? Double {
            request.speed = speed
        }
        if let fileData = json["file_data"] as? Data {
            request.fileData = fileData
        }
        if let fileName = json["file_name"] as? String {
            request.fileName = fileName
        }
        if let language = json["language"] as? String {
            request.language = language
        }
        
        if let toolsArray = json["tools"] as? [[String: Any]] {
            request.tools = try toolsArray.map { toolDict in
                guard let type = toolDict["type"] as? String,
                      let functionDict = toolDict["function"] as? [String: Any],
                      let name = functionDict["name"] as? String,
                      let description = functionDict["description"] as? String,
                      let parametersDict = functionDict["parameters"] as? [String: Any],
                      let parametersType = parametersDict["type"] as? String,
                      let propertiesDict = parametersDict["properties"] as? [String: [String: Any]],
                      let required = parametersDict["required"] as? [String] else {
                    throw LLMRequestError.invalidToolFormat
                }
                
                let properties = try propertiesDict.mapValues { propertyDict -> Property in
                    guard let type = propertyDict["type"] as? String else {
                        throw LLMRequestError.invalidToolFormat
                    }
                    return Property(
                        type: type,
                        description: propertyDict["description"] as? String,
                        enums: propertyDict["enums"] as? [String]
                    )
                }
                
                let parameters = Parameters(type: parametersType, properties: properties, required: required)
                let function = Function(name: name, description: description, parameters: parameters)
                return Tool(type: type, function: function)
            }
        }
        
        if let toolChoice = json["tool_choice"] as? String {
            request.toolChoice = toolChoice
        }
        
        return request
    }
}

public enum LLMRequestError: Error {
    case missingRequiredField(String)
    case invalidToolFormat
}
