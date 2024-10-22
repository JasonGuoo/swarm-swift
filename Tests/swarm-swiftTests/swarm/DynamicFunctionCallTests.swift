import XCTest
@testable import swarm_swift

class DynamicFunctionCallTests: XCTestCase {
    
    class WeatherAgent: Agent {
        @objc func get_current_weatherWithArgs(_ args: [String: Any]) -> Data {
            let location = args["location"] as? String ?? "Unknown"
            let unit = args["unit"] as? String ?? "fahrenheit"
            let returnvalue = "Current weather in \(location): 25°\(unit)"
            let result = SwarmResult(messages: [LLMMessage(role: "function", content: returnvalue)])
            return try! JSONEncoder().encode(result)
        }
        
        override init(name: String = "WeatherAgent",
                      model: String = "gpt-4",
                      instructions: @escaping (() -> String) = { "You are a helpful weather agent." },
                      functions: [LLMRequest.Tool]? = nil,
                      toolChoice: String? = "auto",
                      parallelToolCalls: Bool? = true) {
            let weatherFunction = LLMRequest.Tool(type: "function", function: LLMRequest.Function(
                name: "get_current_weather",
                description: "Get the current weather for a location",
                parameters: LLMRequest.Parameters(
                    type: "object",
                    properties: [
                        "location": LLMRequest.Property(type: "string", description: "The city and state, e.g. San Francisco, CA"),
                        "unit": LLMRequest.Property(type: "string", enum: ["celsius", "fahrenheit"])
                    ],
                    required: ["location"]
                )
            ))
            
            super.init(name: name,
                       model: model,
                       instructions: instructions,
                       functions: functions ?? [weatherFunction],
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
                let result = SwarmResult(messages: [LLMMessage(role: "function", content: "Error: Invalid arguments")])
                return try! JSONEncoder().encode(result)
            }
            let returnvalue = a + b
            let result = SwarmResult(messages: [LLMMessage(role: "function", content: "\(returnvalue)")])
            return try! JSONEncoder().encode(result)
        }
        
        override init(name: String = "CalculatorAgent",
                      model: String = "gpt-4",
                      instructions: @escaping (() -> String) = { "You are a helpful calculator agent." },
                      functions: [LLMRequest.Tool]? = nil,
                      toolChoice: String? = "auto",
                      parallelToolCalls: Bool? = true) {
            let addFunction = LLMRequest.Tool(type: "function", function: LLMRequest.Function(
                name: "add",
                description: "Add two numbers",
                parameters: LLMRequest.Parameters(
                    type: "object",
                    properties: [
                        "a": LLMRequest.Property(type: "number", description: "The first number"),
                        "b": LLMRequest.Property(type: "number", description: "The second number")
                    ],
                    required: ["a", "b"]
                )
            ))
            
            super.init(name: name,
                       model: model,
                       instructions: instructions,
                       functions: functions ?? [addFunction],
                       toolChoice: toolChoice,
                       parallelToolCalls: parallelToolCalls)
        }
        
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
        }
    }
    
    func testWeatherAgentDynamicCall() throws {
        let agent = WeatherAgent()
        let result = try callFunction(agent: agent, functionName: "get_current_weather", arguments: ["location": "New York", "unit": "celsius"])
        
        XCTAssertTrue(result is SwarmResult)
        if let swarmResult = result as? SwarmResult {
            XCTAssertEqual(swarmResult.messages?.first?.content, "Current weather in New York: 25°celsius")
        } else {
            XCTFail("Expected SwarmResult")
        }
    }
    
    func testCalculatorAgentDynamicCall() throws {
        let agent = CalculatorAgent()
        let result = try callFunction(agent: agent, functionName: "add", arguments: ["a": 5.0, "b": 3.0])
        
        XCTAssertTrue(result is SwarmResult)
        if let swarmResult = result as? SwarmResult {
            XCTAssertEqual(swarmResult.messages?.first?.content, "8.0")
        } else {
            XCTFail("Expected SwarmResult")
        }
    }
    
    func testMissingRequiredParameter() throws {
        let agent = WeatherAgent()
        XCTAssertThrowsError(try callFunction(agent: agent, functionName: "get_current_weather", arguments: ["unit": "celsius"])) { error in
            XCTAssertEqual(error as? FunctionCallError, .missingRequiredParameter("location"))
        }
    }
    
    func testFunctionNotFound() throws {
        let agent = WeatherAgent()
        XCTAssertThrowsError(try callFunction(agent: agent, functionName: "nonexistent_function", arguments: [:])) { error in
            XCTAssertEqual(error as? FunctionCallError, .functionNotFound("nonexistent_function"))
        }
    }
}
