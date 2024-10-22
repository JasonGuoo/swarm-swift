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

// MARK: - How to Implement a Custom Agent

/**
 How to Implement a Custom Agent
 
 To create your own custom agent, follow these steps:
 
 1. Create a new class that inherits from Agent:
    ```
    class MyCustomAgent: Agent {
        // Custom properties and methods
    }
    ```
 
 2. Override the initializer:
    ```
    override init(name: String = "MyCustomAgent",
                  model: String = "gpt-4",
                  instructions: @escaping (() -> String) = { "You are a helpful custom agent." },
                  functions: [LLMRequest.Tool]? = nil,
                  toolChoice: String? = "auto",
                  parallelToolCalls: Bool? = true) {
        // Custom initialization
        super.init(name: name,
                   model: model,
                   instructions: instructions,
                   functions: functions ?? [/* Your custom functions */],
                   toolChoice: toolChoice,
                   parallelToolCalls: parallelToolCalls)
    }
    ```
 
 3. Implement the required initializer for Codable conformance:
    ```
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    ```
 
 4. Define your custom functions:
    - Use the @objc attribute to make the function visible to Objective-C runtime
    - Name your function with the "WithArgs" suffix
    - Accept a single [String: Any] parameter
    - Return Data (encoded SwarmResult)
    - Parse the arguments inside the function
    
    Example:
    ```
    @objc func myCustomFunctionWithArgs(_ args: [String: Any]) -> Data {
        // Parse args
        let param1 = args["param1"] as? String ?? "default"
        let param2 = args["param2"] as? Int ?? 0
        
        // Perform your custom logic
        let result = "Processed: \(param1), \(param2)"
        
        // Create and encode SwarmResult
        let swarmResult = SwarmResult(messages: [LLMMessage(role: "function", content: result)])
        return try! JSONEncoder().encode(swarmResult)
    }
    ```
    
    Note: Swift doesn't support dynamic method calling like Python. We use the Objective-C runtime
    to achieve similar functionality. This requires us to:
    a) Use the @objc attribute to make the function visible to Objective-C.
    b) Follow a specific naming convention (adding "WithArgs" suffix).
    c) Accept all arguments in a single [String: Any] dictionary and parse them inside the function.
    d) Encode the SwarmResult as Data, which will be decoded later in the callFunction method.
    
    This approach allows us to call methods dynamically while still using Swift's type system
    and keeping the SwarmResult structure intact through the Objective-C boundary.
 
 5. Define the function description in the initializer:
    ```
    let myCustomFunction = LLMRequest.Tool(type: "function", function: LLMRequest.Function(
        name: "my_custom_function",
        description: "Description of what your function does",
        parameters: LLMRequest.Parameters(
            type: "object",
            properties: [
                "param1": LLMRequest.Property(type: "string", description: "Description of param1"),
                "param2": LLMRequest.Property(type: "number", description: "Description of param2")
            ],
            required: ["param1", "param2"]
        )
    ))
    ```
    
    Important: The 'name' field in the LLMRequest.Function should match the base name of your
    function (without the "WithArgs" suffix). This name is used to find the correct function
    to call, and the "WithArgs" suffix is added programmatically when needed.
 
 6. Add the function to the `functions` array in the initializer:
    ```
    super.init(name: name,
               model: model,
               instructions: instructions,
               functions: functions ?? [myCustomFunction],
               toolChoice: toolChoice,
               parallelToolCalls: parallelToolCalls)
    ```
 
 By following these steps, you can create a custom agent that can be used with the Swarm framework.
 The custom functions you define will be callable using the `callFunction` method in `Util.swift`.
 
 Remember:
 - Your function must accept all arguments in a single [String: Any] dictionary.
 - You need to parse and validate the arguments inside your function.
 - Handle errors appropriately in your function implementation.
 - Ensure that your function's implementation matches the description and parameters you provide
   in the function definition.
 - The encoding and decoding of SwarmResult is handled automatically by the framework, but be
   aware that this process is happening behind the scenes.
 */
