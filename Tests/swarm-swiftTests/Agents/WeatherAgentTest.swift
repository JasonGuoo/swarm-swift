import XCTest
import SwiftyJSON
@testable import swarm_swift

class WeatherAgent: Agent {
    override init(name: String = "Weather Agent",
                  model: String? = "gpt-4",
                  instructions: @escaping (() -> String) = { "You are a helpful weather agent." },
                  functions: JSON? = nil,
                  toolChoice: String? = "auto",
                  parallelToolCalls: Bool? = true) {
        
        let getWeatherFunction = JSON([
            "type": "function",
            "function": [
                "name": "get_weather",
                "description": "Get the current weather in a given location. Location MUST be a city.",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "location": ["type": "string", "description": "The city to get weather for"],
                        "time": ["type": "string", "description": "The time to get weather for, default is 'now'"]
                    ],
                    "required": ["location"]
                ]
            ]
        ])
        
        let sendEmailFunction = JSON([
            "type": "function",
            "function": [
                "name": "send_email",
                "description": "Send an email to a recipient",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "recipient": ["type": "string", "description": "The email recipient"],
                        "subject": ["type": "string", "description": "The email subject"],
                        "body": ["type": "string", "description": "The email body"]
                    ],
                    "required": ["recipient", "subject", "body"]
                ]
            ]
        ])
        
        let agentFunctions = functions ?? JSON([getWeatherFunction, sendEmailFunction])
        
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
    
    @objc func get_weather(_ args: [String: Any]) -> Data {
        let location = args["location"] as? String ?? "Unknown"
        let time = args["time"] as? String ?? "now"
        let weatherData = ["location": location, "temperature": "65", "time": time]
        let result = SwarmResult(messages: [Message().withRole(role: "function").withContent(content: JSON(weatherData).rawString() ?? "")])
        return try! JSONEncoder().encode(result)
    }
    
    @objc func send_email(_ args: [String: Any]) -> Data {
        let recipient = args["recipient"] as? String ?? ""
        let subject = args["subject"] as? String ?? ""
        let body = args["body"] as? String ?? ""
        
        print("Sending email...")
        print("To: \(recipient)")
        print("Subject: \(subject)")
        print("Body: \(body)")
        
        let result = SwarmResult(messages: [Message().withRole(role: "function").withContent(content: "Sent!")])
        return try! JSONEncoder().encode(result)
    }
    
    @objc func get_info(_ args: [String: Any]) -> Data {
        var result = JSON(args)
        let returnData = SwarmResult(messages: [Message().withRole(role: "function").withContent(content: result.rawString() ?? "")])
        return try! JSONEncoder().encode(returnData)
    }
}

class WeatherAgentTest: XCTestCase {
    
    var weatherAgent: WeatherAgent!
    
    override func setUp() {
        super.setUp()
        
        // Create the WeatherAgent
        weatherAgent = WeatherAgent()
    }
    
    func testWeatherAgentInitialization() {
        XCTAssertEqual(weatherAgent.name, "Weather Agent")
        XCTAssertEqual(weatherAgent.model, "gpt-4")
        XCTAssertEqual(weatherAgent.instructions, "You are a helpful weather agent.")
        XCTAssertEqual(weatherAgent.functions?.count, 2)
    }
    
//    func testGetWeatherFunction() {
//        let arguments = ["location": "New York", "time": "now"]
//
//        let result = weatherAgent.get_weatherWithArgs(arguments)
//
//        do {
//            let swarmResult = try JSONDecoder().decode(SwarmResult.self, from: result)
//            if let message = swarmResult.messages?.arrayValue.first,
//               let content = message["content"].string {
//                let weatherData = try JSON(parseJSON: content)
//                print(weatherData)
//                XCTAssertEqual(weatherData["location"].stringValue, "New York")
//                XCTAssertEqual(weatherData["temperature"].stringValue, "65")
//                XCTAssertEqual(weatherData["time"].stringValue, "now")
//            } else {
//                XCTFail("Unexpected result structure")
//            }
//        } catch {
//            XCTFail("Error decoding result: \(error)")
//        }
//    }
    
    func testCallFunctionUtility() {
        // Test get_weather function
        do {
            let getWeatherArgs = ["location": "Paris", "time": "now"]
            let getWeatherResult = try callFunction(agent: weatherAgent, functionName: "get_weather", arguments: JSON(getWeatherArgs).rawString() ?? "")
            
            if let swarmResult = getWeatherResult as? SwarmResult,
               let message = swarmResult.messages?.first,
               let contentStr = message.json["content"].string,
               let weatherData = try? JSON(parseJSON: contentStr) {
                XCTAssertEqual(weatherData["location"].stringValue, "Paris")
                XCTAssertEqual(weatherData["temperature"].stringValue, "65")
                XCTAssertEqual(weatherData["time"].stringValue, "now")
            } else {
                XCTFail("Unexpected result structure for get_weather")
            }
            
            // Test send_email function
            do {
                let sendEmailArgs = ["recipient": "test@example.com", "subject": "Test Subject", "body": "Test Body"]
                let sendEmailResult = try callFunction(agent: weatherAgent, functionName: "send_email", arguments: JSON(sendEmailArgs).rawString() ?? "")
                
                if let swarmResult = sendEmailResult as? SwarmResult,
                   let message = swarmResult.messages?.first {
                    let content = message.json["content"]
                    XCTAssertEqual(content.stringValue, "Sent!")
                } else {
                    XCTFail("Unexpected result structure for send_email")
                }
            } catch {
                XCTFail("Error calling send_email function: \(error)")
            }
        } catch {
            XCTFail("Error calling get_weather function: \(error)")
        }
    }
    
    func testCallFunctionWithInvalidFunction() {
        do {
            let invalidArgs = ["invalid": "argument"]
            _ = try callFunction(agent: weatherAgent, functionName: "invalid_function", arguments: JSON(invalidArgs).rawString() ?? "")
            XCTFail("Expected an error to be thrown")
        } catch FunctionCallError.functionNotFound(let functionName) {
            XCTAssertEqual(functionName, "invalid_function")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCallFunctionWithMissingRequiredParameter() {
        do {
            let incompleteArgs = ["time": "now"] // Missing required 'location' parameter
            _ = try callFunction(agent: weatherAgent, functionName: "get_weather", arguments: JSON(incompleteArgs).rawString() ?? "")
            XCTFail("Expected an error to be thrown")
        } catch FunctionCallError.missingRequiredParameter(let paramName) {
            XCTAssertEqual(paramName, "location")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRunSwarm() {
        let config = TestUtils.loadConfig(for: "ChatGLM")
        
        guard let client = ClientFactory.getLLMClient(apiType: "ChatGLM", config: config) else {
            XCTFail("Failed to create LLMClient for ChatGLM")
            return
        }
        
        let swarm = Swarm(client: client)
        let message = Message().withRole(role: "user").withContent(content: "What is the weather in Paris")
        let result = swarm.run(agent: weatherAgent, messages: [message], contextVariables: [:])
        XCTAssertNotNil(result)
    }
}
