import Foundation
import SwiftyJSON

/**
 Example of an Agent that demonstrates context-aware function implementation.
 
 Note on Context Handling in Swift:
 Unlike Java (with reflection) or Python (with dynamic properties), Swift requires explicit
 context handling. This example shows how to:
 1. Access context from function arguments
 2. Use context values in function logic
 3. Maintain type safety when working with context
 */
class ContextAwareAgent: Agent {
    override init(
        name: String = "ContextAwareAgent",
        model: String? = nil,
        instructions: @escaping (() -> String) = { "You are a context-aware agent that can access and use context variables." },
        functions: JSON? = nil,
        toolChoice: String? = "auto",
        parallelToolCalls: Bool? = true
    ) {
        print(" Initializing ContextAwareAgent...")
        
        // Define the function with its schema
        let processWithContext = JSON([
            "type": "function",
            "function": [
                "name": "process_with_context",
                "description": "Process data using both direct arguments and context variables",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "input_data": [
                            "type": "string",
                            "description": "The input data to process"
                        ]
                    ],
                    "required": ["input_data"]
                ]
            ]
        ])
        
        print(" Registered function: process_with_context")
        
        super.init(
            name: name,
            model: model,
            instructions: instructions,
            functions: functions ?? JSON([processWithContext]),
            toolChoice: toolChoice,
            parallelToolCalls: parallelToolCalls
        )
        
        print(" ContextAwareAgent initialization complete")
    }
    
    required init(from decoder: Decoder) throws {
        print(" Decoding ContextAwareAgent...")
        try super.init(from: decoder)
        print(" ContextAwareAgent decoded successfully")
    }
    
    /**
     Example of a context-aware function implementation.
     
     This function demonstrates how to:
     1. Extract context from the args dictionary
     2. Use both direct arguments and context values
     3. Handle missing context gracefully
     4. Return properly formatted results
     
     Note: The "_context" key is used to access context variables injected by the framework.
     */
    @objc func process_with_context(_ args: [String: Any]) -> Data {
        print("\n Starting process_with_context...")
        print(" Received args:", args)
        
        // 1. Extract context from args
        let context = args["_context"] as? [String: String]
        print(" Extracted context:", context ?? "No context found")
        
        // 2. Get direct arguments
        let inputData = args["input_data"] as? String ?? "no input"
        print(" Input data:", inputData)
        
        // 3. Access context variables (with safe fallbacks)
        let userID = context?["user_id"] ?? "unknown"
        let sessionID = context?["session_id"] ?? "no-session"
        print(" User ID:", userID)
        print(" Session ID:", sessionID)
        
        // 4. Use both context and direct arguments in processing
        let result = """
        Processed input: \(inputData)
        User ID from context: \(userID)
        Session ID from context: \(sessionID)
        Additional context variables: \(context?.filter { $0.key != "user_id" && $0.key != "session_id" } ?? [:])
        """
        
        print(" Generated result:", result)
        
        // 5. Create and return the result
        let message = Message()
            .withRole(role: "tool")
            .withContent(content: result)
        
        let swarmResult = SwarmResult(messages: [message])
        print(" Function execution complete\n")
        return try! JSONEncoder().encode(swarmResult)
    }
}

// Example usage:
/*
 let agent = ContextAwareAgent()
 let swarm = Swarm(client: yourLLMClient)
 
 let result = swarm.run(
     agent: agent,
     messages: [Message().withRole(role: "user").withContent(content: "Process my data")],
     contextVariables: [
         "user_id": "user123",
         "session_id": "sess456"
     ]
 )
 */
