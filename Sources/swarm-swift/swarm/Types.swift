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
    
    public override var description: String {
        let options: JSONSerialization.WritingOptions = [.prettyPrinted]
        let jsonObject: [String: Any] = [
            "name": name,
            "model": model,
            "instructions": instructions ?? NSNull(),
            "functions": functions?.object ?? NSNull(),
            "toolChoice": toolChoice ?? NSNull(),
            "parallelToolCalls": parallelToolCalls ?? NSNull()
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: options),
           let prettyPrintedString = String(data: jsonData, encoding: .utf8) {
            return prettyPrintedString
        }
        
        // Fallback to a basic description if JSON serialization fails
        return """
        Agent(
            name: \(name),
            model: \(model),
            instructions: \(instructions ?? "nil"),
            functions: \(functions?.description ?? "nil"),
            toolChoice: \(toolChoice ?? "nil"),
            parallelToolCalls: \(parallelToolCalls ?? true)
        )
        """
    }
}

public class SwarmResult: Codable, CustomStringConvertible {
    public var messages: [Message]?
    public var agent: Agent?
    public var contextVariables: [String: String]?
    
    public init(messages: [Message]? = nil, agent: Agent? = nil, contextVariables: [String: String]? = nil) {
        self.messages = messages
        self.agent = agent
        self.contextVariables = contextVariables
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = try container.decodeIfPresent([Message].self, forKey: .messages)
        agent = try container.decodeIfPresent(Agent.self, forKey: .agent)
        contextVariables = try container.decodeIfPresent([String: String].self, forKey: .contextVariables)
    }
    
    enum CodingKeys: String, CodingKey {
        case messages, agent, contextVariables
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(messages, forKey: .messages)
        try container.encodeIfPresent(agent, forKey: .agent)
        try container.encodeIfPresent(contextVariables, forKey: .contextVariables)
    }
    
    public var description: String {
        let options: JSONSerialization.WritingOptions = [.prettyPrinted]
        var jsonObject: [String: Any] = [:]
        
        if let messages = messages {
            jsonObject["messages"] = messages.map { $0.json.object }
        }
        
        if let agent = agent {
            jsonObject["agent"] = agent.description
        }
        
        if let contextVariables = contextVariables {
            jsonObject["contextVariables"] = contextVariables
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: options),
           let prettyPrintedString = String(data: jsonData, encoding: .utf8) {
            return prettyPrintedString
        }
        
        // Fallback to a basic description if JSON serialization fails
        return """
        SwarmResult(
            messages: \(messages?.description ?? "nil"),
            agent: \(agent?.description ?? "nil"),
            contextVariables: \(contextVariables?.description ?? "nil")
        )
        """
    }
}

// MARK: - How to Implement a Custom Agent
/**
 To create your own custom agent, follow these steps:
 
 1. Create a new class that inherits from Agent:
    ```swift
    class MyCustomAgent: Agent {
        override init(name: String = "My Custom Agent",
                     model: String = "gpt-4",
                     instructions: @escaping (() -> String) = { "You are a helpful custom agent." },
                     functions: JSON? = nil,
                     toolChoice: String? = "auto",
                     parallelToolCalls: Bool? = true) {
            // Define your custom functions here
            let customFunction = JSON([
                "type": "function",
                "function": [
                    "name": "my_function",
                    "description": "Description of what your function does",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "param1": ["type": "string", "description": "Description of param1"],
                            "param2": ["type": "integer", "description": "Description of param2"]
                        ],
                        "required": ["param1"]
                    ]
                ]
            ])
            
            // Pass your functions to super.init
            let agentFunctions = functions ?? JSON([customFunction])
            super.init(name: name,
                      model: model,
                      instructions: instructions,
                      functions: agentFunctions,
                      toolChoice: toolChoice,
                      parallelToolCalls: parallelToolCalls)
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
        
        // Implement your custom functions
        @objc func my_function(_ args: [String: Any]) -> Any {
            // Parse arguments
            let param1 = args["param1"] as? String ?? ""
            let param2 = args["param2"] as? Int ?? 0
            
            // Your custom logic here
            return "Result: \(param1), \(param2)"
        }
    }
    ```
 
 2. Define your custom functions in the initializer:
    - Use JSON format to define function signatures
    - Include name, description, and parameters
    - Specify required parameters
 
 3. Implement your custom functions:
    - Use the @objc attribute for dynamic function calls
    - Accept a single [String: Any] parameter
    - Return String for function results or Agent for agent switching
    - Handle argument parsing and validation
 
 4. Use your custom agent:
    ```swift
    let myAgent = MyCustomAgent()
    let swarm = Swarm(client: llmClient)
    let result = swarm.run(agent: myAgent, messages: [], contextVariables: [:])
    ```
 */
