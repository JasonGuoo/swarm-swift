import Foundation
import SwiftyJSON

/**
 Request class for constructing LLM API requests.

 Example API Requests:

 1. Simple chat completion request:
 {
     "model": "gpt-4",
     "messages": [
         {"role": "system", "content": "You are a helpful assistant."},
         {"role": "user", "content": "Hello!"}
     ],
     "temperature": 0.7
 }

 2. Function calling request:
 {
     "model": "gpt-4",
     "messages": [
         {"role": "user", "content": "What's the weather like in Boston?"}
     ],
     "tools": [
         {
             "type": "function",
             "function": {
                 "name": "get_current_weather",
                 "description": "Get the current weather in a given location",
                 "parameters": {
                     "type": "object",
                     "properties": {
                         "location": {
                             "type": "string",
                             "description": "The city and state, e.g. San Francisco, CA"
                         },
                         "unit": {
                             "type": "string",
                             "enum": ["celsius", "fahrenheit"]
                         }
                     },
                     "required": ["location"]
                 }
             }
         }
     ],
     "tool_choice": "auto"
 }

 Usage examples:

 1. Creating a simple chat completion request:
    let request = Request()
    request.withModel("gpt-4")
    request.withTemperature(0.7)

    let systemMessage = Message()
    systemMessage.withRole("system")
    systemMessage.withContent("You are a helpful assistant.")
    request.appendMessage(systemMessage)

    let userMessage = Message()
    userMessage.withRole("user")
    userMessage.withContent("Hello!")
    request.appendMessage(userMessage)

 2. Creating a function calling request:
    let request = Request()
    request.withModel("gpt-4")

    let userMessage = Message()
    userMessage.withRole("user")
    userMessage.withContent("What's the weather like in Boston?")
    request.appendMessage(userMessage)

    let tools: [[String: Any]] = [
        [
            "type": "function",
            "function": [
                "name": "get_current_weather",
                "description": "Get the current weather in a given location",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "location": [
                            "type": "string",
                            "description": "The city and state, e.g. San Francisco, CA"
                        ],
                        "unit": [
                            "type": "string",
                            "enum": ["celsius", "fahrenheit"]
                        ]
                    ],
                    "required": ["location"]
                ]
            ]
        ]
    ]
    request.withTools(tools)
    request.withToolChoice(["type": "auto"])
*/
public class Request: MessageBase {
    
    public func withModel(model:String) {
        json["model"] = JSON(model)
    }
    
    public func appendMessage(message:Message) {
        if json["messages"].exists() {
            if json["messages"].type == .null {
                // Initialize "messages" as an empty array if it is null
                json["messages"] = JSON([])
            }
        } else {
            // Initialize "messages" as an empty array if the key does not exist
            json["messages"] = JSON([])
        }
        
        json[CodingKeys.messages.rawValue].arrayObject?.append(message.json.object)
    }
    
    public func appendMessages(messages: [Message])
    {
        for message in messages {
            appendMessage(message: message)
        }
    }
    
    public func withMaxTokens(_ maxTokens: Int) {
        json[CodingKeys.maxTokens.rawValue].int = maxTokens
    }
    
    public func withTemperature(_ temperature: NSDecimalNumber) {
        json[CodingKeys.temperature.rawValue] = JSON(temperature)
    }
    
    public func withTopP(_ topP: NSDecimalNumber) {
        json[CodingKeys.topP.rawValue] = JSON(topP)
    }
    
    public func withN(_ n: Int) {
        json[CodingKeys.n.rawValue].int = n
    }
    
    public func withStream(_ stream: Bool) {
        json[CodingKeys.stream.rawValue].bool = stream
    }
    
    public func withStop(_ stop: [String]) {
        json[CodingKeys.stop.rawValue] = JSON(stop)
    }
    
    public func withPresencePenalty(_ presencePenalty: Float) {
        json[CodingKeys.presencePenalty.rawValue].float = presencePenalty
    }
    
    public func withFrequencyPenalty(_ frequencyPenalty: Float) {
        json[CodingKeys.frequencyPenalty.rawValue].float = frequencyPenalty
    }
    
    public func withLogitBias(_ logitBias: [String: Int]) {
        json[CodingKeys.logitBias.rawValue] = JSON(logitBias)
    }
    
    public func withUser(_ user: String) {
        json[CodingKeys.user.rawValue] = JSON(user)
    }
    
    public func withVoice(_ voice: String) {
        json[CodingKeys.voice.rawValue] = JSON(voice)
    }
    
    public func withResponseFormat(_ responseFormat: [String: String]) {
        json[CodingKeys.responseFormat.rawValue] = JSON(responseFormat)
    }
    
    public func withSpeed(_ speed: Float) {
        json[CodingKeys.speed.rawValue].float = speed
    }
    
    public func withFileData(_ fileData: Data) {
        json[CodingKeys.fileData.rawValue] = JSON(fileData.base64EncodedString())
    }
    
    public func withFileName(_ fileName: String) {
        json[CodingKeys.fileName.rawValue] = JSON(fileName)
    }
    
    public func withLanguage(_ language: String) {
        json[CodingKeys.language.rawValue] = JSON(language)
    }
    
    public func withTools(_ tools: [[String: Any]]) {
        json[CodingKeys.tools.rawValue] = JSON(tools)
    }
    
    public func withToolChoice(_ toolChoice: [String: Any]) {
        json[CodingKeys.toolChoice.rawValue] = JSON(toolChoice)
    }
    
    public func withAdditionalParameters(_ additionalParameters: [String: Any]) {
        json[CodingKeys.additionalParameters.rawValue] = JSON(additionalParameters)
    }
    
    /**
     Appends a function definition to the tools array.

     - Parameters:
       - name: The name of the function.
       - description: A description of what the function does.
       - parameters: A dictionary describing the function's parameters.

     Usage example:
     ```
     request.appendFunction(
         name: "get_current_weather",
         description: "Get the current weather in a given location",
         parameters: [
             "type": "object",
             "properties": [
                 "location": [
                     "type": "string",
                     "description": "The city and state, e.g. San Francisco, CA"
                 ],
                 "unit": [
                     "type": "string",
                     "enum": ["celsius", "fahrenheit"]
                 ]
             ],
             "required": ["location"]
         ]
     )
     ```
    */
    public func appendFunction(name: String, description: String, parameters: [String: Any]) {
        var tools: [[String: Any]] = json[CodingKeys.tools.rawValue].arrayValue.map { $0.dictionaryObject ?? [:] }
        
        let function: [String: Any] = [
            "type": "function",
            "function": [
                "name": name,
                "description": description,
                "parameters": parameters
            ]
        ]
        
        tools.append(function)
        json[CodingKeys.tools.rawValue] = JSON(tools)
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

    public func getMessages() -> [Message] {
        guard let messagesArray = json[CodingKeys.messages.rawValue].array else {
            return []
        }
        
        return messagesArray.map { messageJSON in
            let message = Message()
            message.json = messageJSON
            return message
        }
    }
}

public enum LLMRequestError: Error {
    case invalidJSONFormat
    case missingRequiredField(String)
    case invalidToolFormat
    case invalidJSONString
}
