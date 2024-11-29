import XCTest
@testable import swarm_swift
import SwiftyJSON

class DynamicFunctionCallTests: XCTestCase {
    
    class WeatherAgent: Agent {
        @objc func get_current_weatherWithArgs(_ args: [String: Any]) -> Data {
            let location = args["location"] as? String ?? "Unknown"
            let unit = args["unit"] as? String ?? "fahrenheit"
            let returnvalue = "Current weather in \(location): 25°\(unit)"
            let result = SwarmResult(messages: [Message().withRole(role: "tool").withContent(content: returnvalue)])
            return try! JSONEncoder().encode(result)
        }
        
        override init(name: String = "WeatherAgent",
                      model: String = "gpt-4",
                      instructions: @escaping (() -> String) = { "You are a helpful weather agent." },
                      functions: JSON? = nil,
                      toolChoice: String? = "auto",
                      parallelToolCalls: Bool? = true) {
            let weatherFunction = JSON([
                "type": "function",
                "function": [
                    "name": "get_current_weatherWithArgs",
                    "description": "Get the current weather for a location",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "location": ["type": "string", "description": "The city and state, e.g. San Francisco, CA"],
                            "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]]
                        ],
                        "required": ["location"]
                    ]
                ]
            ])
            
            super.init(name: name,
                       model: model,
                       instructions: instructions,
                       functions: functions ?? JSON([weatherFunction]),
                       toolChoice: toolChoice,
                       parallelToolCalls: parallelToolCalls)
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    class CalculatorAgent: Agent {
        @objc func addWithArgs(_ args: [String: Any]) -> Data {
            guard let a = args["a"] as? Double,
                  let b = args["b"] as? Double else {
                let result = SwarmResult(messages: [Message().withRole(role: "tool").withContent(content: "Error: Invalid arguments")])
                return try! JSONEncoder().encode(result)
            }
            let returnvalue = a + b
            let result = SwarmResult(messages: [Message().withRole(role: "tool").withContent(content: "\(returnvalue)")])
            return try! JSONEncoder().encode(result)
        }
        
        override init(name: String = "CalculatorAgent",
                      model: String = "gpt-4",
                      instructions: @escaping (() -> String) = { "You are a helpful calculator agent." },
                      functions: JSON? = nil,
                      toolChoice: String? = "auto",
                      parallelToolCalls: Bool? = true) {
            let addFunction = JSON([
                "type": "function",
                "function": [
                    "name": "addWithArgs",
                    "description": "Add two numbers",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "a": ["type": "number", "description": "The first number"],
                            "b": ["type": "number", "description": "The second number"]
                        ],
                        "required": ["a", "b"]
                    ]
                ]
            ])
            
            super.init(name: name,
                       model: model,
                       instructions: instructions,
                       functions: functions ?? JSON([addFunction]),
                       toolChoice: toolChoice,
                       parallelToolCalls: parallelToolCalls)
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    func testWeatherAgentDynamicCall() throws {
        let agent = WeatherAgent()
        
        // Print function name and generated selector
        print("\n=== Weather Agent Test ===")
        print("Function name: get_current_weatherWithArgs")
        print("Generated selector: \(NSSelectorFromString("get_current_weatherWithArgs:"))")
        
        // Print available methods on the agent
        let methods = class_copyMethodList(type(of: agent), UnsafeMutablePointer<UInt32>.allocate(capacity: 1))
        defer { free(methods) }
        print("\nAvailable methods on WeatherAgent:")
        var methodPtr = methods
        while let method = methodPtr?.pointee {
            let selector = method_getName(method)
            print("- \(NSStringFromSelector(selector))")
            methodPtr = methodPtr?.successor()
        }
        
        let result = try callFunction(agent: agent, functionName: "get_current_weatherWithArgs", arguments: "{\"location\": \"New York\", \"unit\": \"celsius\"}")
        print("\nFunction call result:", String(describing: result))
        
        XCTAssertTrue(result is SwarmResult)
        if let swarmResult = result as? SwarmResult {
            XCTAssertEqual(swarmResult.messages?.first?.content(), "Current weather in New York: 25°celsius")
        } else {
            XCTFail("Expected SwarmResult")
        }
    }
    
    func testCalculatorAgentDynamicCall() throws {
        let agent = CalculatorAgent()
        
        // Print function name and generated selector
        print("\n=== Calculator Agent Test ===")
        print("Function name: addWithArgs")
        print("Generated selector: \(NSSelectorFromString("addWithArgs:"))")
        
        // Print available methods on the agent
        let methods = class_copyMethodList(type(of: agent), UnsafeMutablePointer<UInt32>.allocate(capacity: 1))
        defer { free(methods) }
        print("\nAvailable methods on CalculatorAgent:")
        var methodPtr = methods
        while let method = methodPtr?.pointee {
            let selector = method_getName(method)
            print("- \(NSStringFromSelector(selector))")
            methodPtr = methodPtr?.successor()
        }
        
        let result = try callFunction(agent: agent, functionName: "addWithArgs", arguments: "{\"a\": 5.0, \"b\": 3.0}")
        print("\nFunction call result:", String(describing: result))
        
        XCTAssertTrue(result is SwarmResult)
        if let swarmResult = result as? SwarmResult {
            XCTAssertEqual(swarmResult.messages?.first?.content(), "8.0")
        } else {
            XCTFail("Expected SwarmResult")
        }
    }
    
    
    func testFunctionNotFound() throws {
        let agent = WeatherAgent()
        XCTAssertThrowsError(try callFunction(agent: agent, functionName: "nonexistent_function", arguments: "{}")) { error in
            XCTAssertEqual(error as? FunctionCallError, .functionNotFound("nonexistent_function"))
        }
    }
}
