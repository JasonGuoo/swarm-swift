import Foundation

/// Represents an agent in the swarm.
/// Noted that since the swift language does not support dynamic method calling,
/// the function name for dynamic calling is not the original name, but is constructed
/// by joining the parameters with "WithArgs:"
/// For example, a function get_current_weather(location, unit)
/// would be dynamically called using the name "get_current_weatherWithArgs:"
/// The function that will be called by the LLM should conform the conventions as:
/// func functionName(args: [String: Any]) -> SwarmResult
/// The args dictionary will contain all the parameters that are required by the function.
/// Example of a subclass of the Agent class:
/// class WeatherAgent: Agent {
///     func get_current_weather(args: [String: Any]) -> SwarmResult {
///         let location = args["location"] as? String ?? "Unknown"
///         let unit = args["unit"] as? String ?? "fahrenheit"
///         let result = "Current weather in \(location): 25°\(unit)"
///         return SwarmResult(value: result)
///     }
/// }
/// Then the LLM can call the function get_current_weather with the arguments:
/// {"location": "New York", "unit": "C"}
/// The function will return a SwarmResult with the value "Current weather in New York: 25°C"
public class Agent: NSObject, Codable {
    var name: String
    var model: String
    var instructions: String?
    var functions: [LLMRequest.Tool]? // Changed to optional
    var toolChoice: String? 
    var parallelToolCalls: Bool? = true
    
    init(name: String = "Agent",
         model: String = "gpt-4o",
         instructions: @escaping (() -> String) = { "You are a helpful agent." },
         functions: [LLMRequest.Tool]? = nil, // Changed to optional with default value nil
         toolChoice: String? = "auto",
         parallelToolCalls: Bool? = true) {
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
        functions = try container.decodeIfPresent([LLMRequest.Tool].self, forKey: .functions) // Changed to decodeIfPresent
        toolChoice = try container.decodeIfPresent(String.self, forKey: .toolChoice)
        parallelToolCalls = try container.decodeIfPresent(Bool.self, forKey: .parallelToolCalls) ?? true
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(model, forKey: .model)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(functions, forKey: .functions) // Changed to encodeIfPresent
        try container.encodeIfPresent(toolChoice, forKey: .toolChoice)
        try container.encode(parallelToolCalls, forKey: .parallelToolCalls)
    }
}

public class SwarmResult: Codable {
    public var messages: [LLMMessage]?
    public var agent: Agent?
    public var contextVariables: [String: String]?
    
    public init(messages: [LLMMessage]? = nil, agent: Agent? = nil, contextVariables: [String: String]? = nil) {
        self.messages = messages
        self.agent = agent
        self.contextVariables = contextVariables
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = try container.decode([LLMMessage].self, forKey: .messages)
        agent = try container.decodeIfPresent(Agent.self, forKey: .agent)
        contextVariables = try container.decodeIfPresent([String: String].self, forKey: .contextVariables)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messages, forKey: .messages)
        try container.encodeIfPresent(agent, forKey: .agent)
        try container.encodeIfPresent(contextVariables, forKey: .contextVariables)
    }
    
    private enum CodingKeys: String, CodingKey {
        case messages, agent, contextVariables
    }
}
