import Foundation

public struct LLMRequest: Codable {
    public static let defaultMaxTokens = 4096
    public static let defaultTemperature = 0.7
    public static let defaultTopP = 1.0
    public static let defaultFrequencyPenalty = 0.0
    public static let defaultPresencePenalty = 0.0
    public static let defaultStop: [String] = []

    public var model: String
    public var messages: [LLMMessage]
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
    public var additionalParameters: [String: AnyCodable]?

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
        public var `enum`: [String]?
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
        case additionalParameters
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all properties
        model = try container.decode(String.self, forKey: .model)
        messages = try container.decode([LLMMessage].self, forKey: .messages)
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature)
        topP = try container.decodeIfPresent(Double.self, forKey: .topP)
        n = try container.decodeIfPresent(Int.self, forKey: .n)
        stream = try container.decodeIfPresent(Bool.self, forKey: .stream)
        stop = try container.decodeIfPresent([String].self, forKey: .stop)
        maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens)
        presencePenalty = try container.decodeIfPresent(Double.self, forKey: .presencePenalty)
        frequencyPenalty = try container.decodeIfPresent(Double.self, forKey: .frequencyPenalty)
        logitBias = try container.decodeIfPresent([String: Int].self, forKey: .logitBias)
        user = try container.decodeIfPresent(String.self, forKey: .user)
        voice = try container.decodeIfPresent(String.self, forKey: .voice)
        responseFormat = try container.decodeIfPresent(String.self, forKey: .responseFormat)
        speed = try container.decodeIfPresent(Double.self, forKey: .speed)
        fileData = try container.decodeIfPresent(Data.self, forKey: .fileData)
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        tools = try container.decodeIfPresent([Tool].self, forKey: .tools)
        toolChoice = try container.decodeIfPresent(String.self, forKey: .toolChoice)
        if let additionalData = try container.decodeIfPresent(Data.self, forKey: .additionalParameters) {
            additionalParameters = try JSONSerialization.jsonObject(with: additionalData) as? [String: AnyCodable]
        }
        
        // Set default values after decoding
        setDefaultValues()
    }

    private mutating func setDefaultValues() {
        if maxTokens == nil {
            maxTokens = LLMRequest.defaultMaxTokens
        }
        if temperature == nil {
            temperature = LLMRequest.defaultTemperature
        }
        if topP == nil {
            topP = LLMRequest.defaultTopP
        }
        if frequencyPenalty == nil {
            frequencyPenalty = LLMRequest.defaultFrequencyPenalty
        }
        if presencePenalty == nil {
            presencePenalty = LLMRequest.defaultPresencePenalty
        }
        if stop == nil {
            stop = LLMRequest.defaultStop
        }
    }

    public init(
        model: String,
        messages: [LLMMessage],
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
        toolChoice: String? = nil,
        additionalParameters: [String: AnyCodable]? = nil
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
        self.additionalParameters = additionalParameters
        
        setDefaultValues()
    }
    
    public var description: String {
        var desc = "LLMRequest:\n"
        desc += "  Model: \(model)\n"
        desc += "  Messages:\n"
        for message in messages {
            desc += "    Role: \(message.role), Content: \(message.content)\n"
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
                    if let enumValues = property.enum {
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
    ///   - messages: An array of LLMMessage structs representing the conversation history.
    ///               Each LLMMessage should have a role (e.g., "system", "user", "assistant") and content.
    ///   - temperature: Controls randomness in the model's output. Default is LLMRequest.defaultTemperature.
    ///   - maxTokens: The maximum number of tokens to generate. Default is nil.
    ///   - stream: Whether to stream the response. Default is nil.
    ///   - additionalParameters: A dictionary of additional parameters to include in the request.
    ///
    /// - Returns: An LLMRequest instance configured with the provided parameters.
    ///
    /// - Example:
    ///   ```swift
    ///   let request = LLMRequest.create(
    ///       model: "gpt-4",
    ///       messages: [
    ///           ["role": "user", "content": "What's the weather like in Boston today?"],
    ///           ["role": "system", "content": "You are a helpful assistant."],
    ///           ["role": "assistant", "content": "I'm sorry, but as an AI language model, I don't have access to real-time weather information. To get accurate and up-to-date weather information for Boston, I recommend checking a reliable weather website or app, or contacting a local weather service."]
    ///       ],
    ///       temperature: 0.8,
    ///       additionalParameters: ["top_p": 0.9, "user": "user123"]
    ///   )
    ///   ```
    public static func create(
        model: String,
        messages: [LLMMessage],
        tools: [Tool]? = nil,
        toolChoice: String? = nil,
        temperature: Double? = LLMRequest.defaultTemperature,
        maxTokens: Int? = defaultMaxTokens,
        stream: Bool? = false,
        additionalParameters: [String: AnyCodable]? = [:]
    ) -> LLMRequest {
        var request = LLMRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            stream: stream,
            maxTokens: maxTokens,
            tools: tools,
            toolChoice: toolChoice
        )
        
        // Apply additional parameters
        if let additionalParams = additionalParameters {
            let keys = additionalParams.keys
            for key in keys {
                let value = additionalParams[key]
                switch key {
                case "topP": request.topP = value?.value as? Double
                case "n": request.n = value?.value as? Int
                case "stop": request.stop = value?.value as? [String]
                case "presencePenalty": request.presencePenalty = value?.value as? Double
                case "frequencyPenalty": request.frequencyPenalty = value?.value as? Double
                case "logitBias": request.logitBias = value?.value as? [String: Int]
                case "user": request.user = value?.value as? String
                case "voice": request.voice = value?.value as? String
                case "responseFormat": request.responseFormat = value?.value as? String
                case "speed": request.speed = value?.value as? Double
                case "fileData": request.fileData = value?.value as? Data
                case "fileName": request.fileName = value?.value as? String
                case "language": request.language = value?.value as? String
                default: break
           }
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
    ///           ["role": "system", "content": "You are a helpful assistant."],
    ///           ["role": "user", "content": "What's the capital of France?"]
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
        
        let messages = messagesArray.compactMap { dict -> LLMMessage? in
            guard let role = dict["role"], let content = dict["content"] else {
                return nil
            }
            return LLMMessage(role: role, content: content)
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
        request.stream = (json["stream"] as? Bool) ?? false

        if let stop = json["stop"] as? [String] {
            request.stop = stop
        }
        request.maxTokens = (json["max_tokens"] as? Int) ?? defaultMaxTokens
        
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
                
                let orderedProperties = propertiesDict.map { (key, value) -> (String, Property) in
                    let property = Property(
                        type: value["type"] as? String ?? "",
                        description: value["description"] as? String,
                        `enum`: value["enum"] as? [String]  // use `` to escape the keyword "enum" in swift
                    )
                    return (key, property)
                }
                
                let parameters = Parameters(
                    type: parametersType,
                    properties: Dictionary(uniqueKeysWithValues: orderedProperties),
                    required: required
                )
                let function = Function(name: name, description: description, parameters: parameters)
                return Tool(type: type, function: function)
            }
        }
        
        if let toolChoice = json["tool_choice"] as? String {
            request.toolChoice = toolChoice
        }
        
        return request
    }

    public static func fromJSONString(_ jsonString: String) throws -> LLMRequest {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw LLMRequestError.invalidJSONString
        }
        
        do {
            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                return try fromJSON(jsonDict)
            } else {
                throw LLMRequestError.invalidJSONFormat
            }
        } catch {
            throw LLMRequestError.invalidJSONString
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // ... encode existing properties ...
        
        if let additionalParameters = additionalParameters {
            let additionalData = try JSONSerialization.data(withJSONObject: additionalParameters)
            try container.encode(additionalData, forKey: .additionalParameters)
        }
    }
}

public enum LLMRequestError: Error {
    case invalidJSONFormat
    case missingRequiredField(String)
    case invalidToolFormat
    case invalidJSONString
}

