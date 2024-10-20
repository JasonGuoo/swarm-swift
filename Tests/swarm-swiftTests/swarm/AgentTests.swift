import XCTest
@testable import swarm_swift

class AgentTests: XCTestCase {
    
    var agent: Agent!
    
    class WeatherAgent : Agent {
//        @objc public func get_current_weather(location:String, unit: String) -> String {
//            return "The \(location)'s is clear, 65 fahrenheit"
//        }
        @objc public func get_current_weather(args : [String: Any]) -> SwarmResult{
            let location = args["location"]
            let unit = args["unit"]
            print( "The method get_current_weather is called. \n The NY's is clear, 65 fahrenheit")
            let locationString = (location as? String) ?? "Unknown"
            let unitString = (unit as? String) ?? "fahrenheit"
            let result = "The \(locationString)'s is clear, 65 \(unitString)"
            return SwarmResult(value: result, agent: self, contextVariables: nil)
        }
    }
    
    func listMethods(of obj: NSObject) {
        let classType: AnyClass = type(of: obj)
        
        var methodCount: UInt32 = 0
        if let methodList = class_copyMethodList(classType, &methodCount) {
            print("Number of methods: \(methodCount)")
            
            for i in 0..<Int(methodCount) {
                let method = methodList[i]
                let methodName = String(describing: method_getName(method))
                print("Method name: \(methodName)")
            }
            // Free the allocated memory
            free(methodList)
        } else {
            print("No methods found or unable to retrieve methods.")
        }
    }
    
    override func setUp() {
        super.setUp()
        // 创建一个测试用的 Agent 实例
        agent = WeatherAgent(name: "TestAgent", model: "gpt4o")
        
        // 添加一些测试函数
        let weatherFunction = LLMRequest.Tool(
                    type: "function",
                    function: LLMRequest.Function(
                        name: "get_current_weather",
                        description: "Get the current weather in a given location",
                        parameters: LLMRequest.Parameters(
                            type: "object",
                            properties: [
                                "location": LLMRequest.Property(
                                    type: "string",
                                    description: "The city and state, e.g. San Francisco, CA"
                                ),
                                "unit": LLMRequest.Property(
                                    type: "string",
                                    `enum`: ["celsius", "fahrenheit"]
                                )
                            ],
                            required: ["location"]
                        )
                    )
                )
        
        agent.functions = [weatherFunction]
    }
    
    func testAgentInitialization() {
        print("Agent name: \(agent.name)")
        print("Agent model: \(agent.model)")
        print("Number of functions: \(agent.functions.count)")
        if let firstFunctionName = agent.functions.first?.function.name {
            print("First function name: \(firstFunctionName)")
        }
        
        XCTAssertEqual(agent.name, "TestAgent", "Agent name mismatch. Actual: \(agent.name)")
        XCTAssertEqual(agent.model, "gpt4o", "Agent model mismatch. Actual: \(agent.model)")
        XCTAssertEqual(agent.functions.count, 1, "Incorrect number of functions. Actual: \(agent.functions.count)")
        XCTAssertEqual(agent.functions[0].function.name, "get_current_weather", "Incorrect function name. Actual: \(agent.functions[0].function.name)")
    }
    
    func testCallFunctionSuccess() {
        do {
            listMethods(of: agent)
            let result = try callFunction(on: agent, with: "get_current_weather", arguments: ["location": "NY", "unit": "fahrenheit"])
            print("Function call result: \(result)")
            
            guard let swarmResult = result as? SwarmResult else {
                XCTFail("Result is not of type SwarmResult")
                return
            }
            
            XCTAssertEqual(swarmResult.value as? String, "The NY's is clear, 65 fahrenheit", "Unexpected result. Actual: \(swarmResult.value ?? "nil")")
            XCTAssertTrue(swarmResult.agent === agent, "SwarmResult agent should be the same as the test agent")
            XCTAssertNil(swarmResult.contextVariables, "contextVariables should be nil")
        } catch {
            XCTFail("Function call failed: \(error)")
        }
    }
    
    func testCallFunctionMissingRequiredParameter() {
        do {
            _ = try callFunction(on: agent, with: "get_current_weather", arguments: ["unit": "fahrenheit"])
            XCTFail("Function call should have failed")
        } catch let error as FunctionCallError {
            print("Caught error: \(error)")
            if case .missingRequiredParameter(let param) = error {
                XCTAssertEqual(param, "location", "Unexpected missing parameter. Actual: \(param)")
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCallFunctionNotFound() {
        do {
            _ = try callFunction(on: agent, with: "nonExistentFunction", arguments: [:])
            XCTFail("Function call should have failed")
        } catch let error as FunctionCallError {
            print("Caught error: \(error)")
            if case .functionNotFound(let name) = error {
                XCTAssertEqual(name, "nonExistentFunction", "Unexpected function name. Actual: \(name)")
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
