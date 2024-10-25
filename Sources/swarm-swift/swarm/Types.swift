import Foundation
import SwiftyJSON

/// Represents an agent in the swarm.
public class Agent: NSObject, Codable {
    var name: String
    var model: String
    var instructions: String?
    var functions: JSON?
    var toolChoice: String? 
    var parallelToolCalls: Bool? = true
    
    init(name: String = "Agent",
         model: String = "gpt-4o",
         instructions: @escaping (() -> String) = { "You are a helpful agent." },
         functions: JSON? = nil,
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
        functions = try container.decodeIfPresent(JSON.self, forKey: .functions)
        toolChoice = try container.decodeIfPresent(String.self, forKey: .toolChoice)
        parallelToolCalls = try container.decodeIfPresent(Bool.self, forKey: .parallelToolCalls) ?? true
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(model, forKey: .model)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(functions, forKey: .functions)
        try container.encodeIfPresent(toolChoice, forKey: .toolChoice)
        try container.encode(parallelToolCalls, forKey: .parallelToolCalls)
    }
}

public class SwarmResult: Codable {
    public var messages: JSON?
    public var agent: Agent?
    public var contextVariables: [String: String]?
    
    public init(messages: JSON? = nil, agent: Agent? = nil, contextVariables: [String: String]? = nil) {
        self.messages = messages
        self.agent = agent
        self.contextVariables = contextVariables
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = try container.decodeIfPresent(JSON.self, forKey: .messages)
        agent = try container.decodeIfPresent(Agent.self, forKey: .agent)
        contextVariables = try container.decodeIfPresent([String: String].self, forKey: .contextVariables)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(messages, forKey: .messages)
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
                  functions: JSON? = nil,
                  toolChoice: String? = "auto",
                  parallelToolCalls: Bool? = true) {
        // Custom initialization
        super.init(name: name,
                   model: model,
                   instructions: instructions,
                   functions: functions ?? JSON([/* Your custom functions */]),
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
    - Keep the function name as same as the function name in the function definition
    - Accept a single [String: Any] parameter
    - Return Data (encoded SwarmResult)
    - Parse the arguments inside the function
    
    Example:
    ```
    @objc func myCustomFunction(_ args: [String: Any]) -> Data {
        // Parse args
        let param1 = args["param1"] as? String ?? "default"
        let param2 = args["param2"] as? Int ?? 0
        
        // Perform your custom logic
        let result = "Processed: \(param1), \(param2)"
        
        // Create and encode SwarmResult
        let swarmResult = SwarmResult(messages: JSON(["role": "function", "content": result]))
        return try! JSONEncoder().encode(swarmResult)
    }
    ```
 
 5. Define the function description in the initializer:
    ```
    let myCustomFunction = JSON([
        "type": "function",
        "function": [
            "name": "my_custom_function",
            "description": "Description of what your function does",
            "parameters": [
                "type": "object",
                "properties": [
                    "param1": ["type": "string", "description": "Description of param1"],
                    "param2": ["type": "number", "description": "Description of param2"]
                ],
                "required": ["param1", "param2"]
            ]
        ]
    ])
    ```
 This JSON description of functions is necessary because Swift lacks the reflection capabilities 
 found in languages like Python. We can't automatically generate these descriptions for functions 
 defined in the Agent. However, when we query the LLM to determine if function calls are needed, 
 it requires detailed information about the available functions.
 
 6. Add the function to the `functions` array in the initializer:
    ```
    super.init(name: name,
               model: model,
               instructions: instructions,
               functions: functions ?? JSON([myCustomFunction]),
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

