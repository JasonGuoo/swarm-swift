import Foundation

public struct ChatCompletionMessage: Codable {
    var role: String
    var content: String?
    var name: String?
    var functionCall: ChatCompletionMessageToolCall?
}

public struct ChatCompletionMessageToolCall: Codable {
    var id: String
    var type: String
    var function: LLMRequest.Function
}

public class Agent: NSObject, Codable {
    var name: String
    var model: String
    var instructions: String?
    var functions: [LLMRequest.Tool] 
    var toolChoice: String? 
    var parallelToolCalls: Bool
    
    init(name: String = "Agent",
         model: String = "gpt-4o",
         instructions: @escaping (() -> String) = { "You are a helpful agent." },
         functions: [LLMRequest.Tool] = [], 
         toolChoice: String? = "auto",
         parallelToolCalls: Bool = true) {
        self.name = name
        self.model = model
        self.instructions = instructions()
        self.functions = functions
        self.toolChoice = toolChoice
        self.parallelToolCalls = parallelToolCalls
        super.init()
    }
    
    enum CodingKeys: String, CodingKey {
        case name, model, instructions, functions, toolChoice, parallelToolCalls
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        model = try container.decode(String.self, forKey: .model)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        functions = try container.decode([LLMRequest.Tool].self, forKey: .functions) // Changed from [String] to [LLMRequest.Tool]
        toolChoice = try container.decodeIfPresent(String.self, forKey: .toolChoice)
        parallelToolCalls = try container.decode(Bool.self, forKey: .parallelToolCalls)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(model, forKey: .model)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encode(functions, forKey: .functions)
        try container.encodeIfPresent(toolChoice, forKey: .toolChoice)
        try container.encode(parallelToolCalls, forKey: .parallelToolCalls)
    }
}

public struct ChatCompletionResponse: Codable {
    var messages: [LLMRequest.Message]
    var agent: Agent?
    var contextVariables: [String: String]
}

@objc public class SwarmResult: NSObject, Codable {
    @objc public var value: String
    @objc public var agent: Agent?
    @objc public var contextVariables: [String: String]?
    
    @objc public init(value: String, agent: Agent? = nil, contextVariables: [String: String]? = nil) {
        self.value = value
        self.agent = agent
        self.contextVariables = contextVariables
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(String.self, forKey: .value)
        agent = try container.decodeIfPresent(Agent.self, forKey: .agent)
        contextVariables = try container.decodeIfPresent([String: String].self, forKey: .contextVariables)
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encodeIfPresent(agent, forKey: .agent)
        try container.encodeIfPresent(contextVariables, forKey: .contextVariables)
    }
    
    private enum CodingKeys: String, CodingKey {
        case value, agent, contextVariables
    }
}
