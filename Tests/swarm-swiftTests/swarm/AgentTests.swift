import XCTest
import SwiftyJSON
@testable import swarm_swift

final class AgentTests: XCTestCase {
    func testAgentCreation() {
        let agent = Agent(name: "TestAgent", model: "gpt4o", instructions: {"You are a test agent."})
        XCTAssertEqual(agent.name, "TestAgent")
        XCTAssertEqual(agent.model, "gpt4o")
        XCTAssertEqual(agent.instructions, "You are a test agent.")
    }
    
    func testAgentCodable() throws {
        let agent = Agent(name: "CodableAgent", model: "gpt3.5-turbo", instructions: {"Test instructions"})
        
        // Test encoding
        let encodedData = try JSONEncoder().encode(agent)
        
        // Test decoding
        let decodedAgent = try JSONDecoder().decode(Agent.self, from: encodedData)
        
        XCTAssertEqual(agent.name, decodedAgent.name)
        XCTAssertEqual(agent.model, decodedAgent.model)
        XCTAssertEqual(agent.instructions, decodedAgent.instructions)
    }
    
    func testAgentCodableWithEmptyFields() throws {
        let agent = Agent(name: "", model: "", instructions: {""})
        
        let encodedData = try JSONEncoder().encode(agent)
        let decodedAgent = try JSONDecoder().decode(Agent.self, from: encodedData)
        
        XCTAssertEqual(agent.name, decodedAgent.name)
        XCTAssertEqual(agent.model, decodedAgent.model)
        XCTAssertEqual(agent.instructions, decodedAgent.instructions)
    }
    
    func testAgentCodableWithSpecialCharacters() throws {
        let agent = Agent(name: "Special!@#$%^&*()_+", model: "model-123", instructions: {"Instructions with 你好世界 and émojis 🎉"})
        
        let encodedData = try JSONEncoder().encode(agent)
        let decodedAgent = try JSONDecoder().decode(Agent.self, from: encodedData)
        
        XCTAssertEqual(agent.name, decodedAgent.name)
        XCTAssertEqual(agent.model, decodedAgent.model)
        XCTAssertEqual(agent.instructions, decodedAgent.instructions)
    }
    
    func testAgentCodableWithLongInstructions() throws {
        let longInstructions = String(repeating: "Long instruction. ", count: 1000)
        let agent = Agent(name: "LongAgent", model: "gpt4", instructions: {longInstructions})
        
        let encodedData = try JSONEncoder().encode(agent)
        let decodedAgent = try JSONDecoder().decode(Agent.self, from: encodedData)
        
        XCTAssertEqual(agent.name, decodedAgent.name)
        XCTAssertEqual(agent.model, decodedAgent.model)
        XCTAssertEqual(agent.instructions, decodedAgent.instructions)
    }
    
    func testAgentCodableWithNilFields() throws {
        let agent = Agent(name: "NilAgent", model: "", instructions: {""})
        
        let encodedData = try JSONEncoder().encode(agent)
        let decodedAgent = try JSONDecoder().decode(Agent.self, from: encodedData)
        
        XCTAssertEqual(agent.name, decodedAgent.name)
        XCTAssertEqual(decodedAgent.model, "")
        XCTAssertEqual(decodedAgent.instructions, "")
    }
    
    func testAgentDecodingCustomDateFormat() throws {
        let jsonString = """
        {
            "name": "DateAgent",
            "model": "gpt3",
            "instructions": "Time-sensitive agent",
            "parallelToolCalls": true
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        let decodedAgent = try decoder.decode(Agent.self, from: jsonData)
        
        XCTAssertEqual(decodedAgent.name, "DateAgent")
        XCTAssertEqual(decodedAgent.model, "gpt3")
        XCTAssertEqual(decodedAgent.instructions, "Time-sensitive agent")
        XCTAssertEqual(decodedAgent.parallelToolCalls, true)
    }
    
    func testAgentEncodingDecoding() throws {
        let functionJSON = JSON([
            "type": "function",
            "function": [
                "name": "get_weather",
                "description": "Get the current weather",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "location": ["type": "string", "description": "The city and state, e.g. San Francisco, CA"],
                        "unit": ["type": "string", "description": "The temperature unit", "enum": ["celsius", "fahrenheit"]]
                    ],
                    "required": ["location"]
                ]
            ]
        ])
        
        let agent = Agent(
            name: "WeatherAgent",
            model: "gpt-4",
            instructions: { "You are a weather assistant." },
            functions: JSON([functionJSON]),
            toolChoice: "auto",
            parallelToolCalls: true
        )
        
        // Test encoding
        let encodedData = try JSONEncoder().encode(agent)
        
        // Test decoding
        let decodedAgent = try JSONDecoder().decode(Agent.self, from: encodedData)
        
        // Assertions
        XCTAssertEqual(agent.name, decodedAgent.name)
        XCTAssertEqual(agent.model, decodedAgent.model)
        XCTAssertEqual(agent.instructions, decodedAgent.instructions)
        XCTAssertEqual(agent.toolChoice, decodedAgent.toolChoice)
        XCTAssertEqual(agent.parallelToolCalls, decodedAgent.parallelToolCalls)
        
        // Check functions
        XCTAssertEqual(agent.functions?.arrayValue.count, decodedAgent.functions?.arrayValue.count)
        XCTAssertEqual(agent.functions?.arrayValue.first?["type"].stringValue, decodedAgent.functions?.arrayValue.first?["type"].stringValue)
        XCTAssertEqual(agent.functions?.arrayValue.first?["function"]["name"].stringValue, decodedAgent.functions?.arrayValue.first?["function"]["name"].stringValue)
        XCTAssertEqual(agent.functions?.arrayValue.first?["function"]["description"].stringValue, decodedAgent.functions?.arrayValue.first?["function"]["description"].stringValue)
    }
    
    func testAgentWithNilFields() throws {
        let agent = Agent(name: "MinimalAgent", model: "gpt-3.5-turbo")
        
        // Test encoding
        let encodedData = try JSONEncoder().encode(agent)
        
        // Test decoding
        let decodedAgent = try JSONDecoder().decode(Agent.self, from: encodedData)
        
        // Assertions
        XCTAssertEqual(agent.name, decodedAgent.name)
        XCTAssertEqual(agent.model, decodedAgent.model)
        XCTAssertEqual(decodedAgent.instructions, "You are a helpful agent.")
        XCTAssertNil(decodedAgent.functions)
        XCTAssertEqual(decodedAgent.toolChoice, "auto")
        XCTAssertEqual(decodedAgent.parallelToolCalls, true) // Default value
    }
    
    func testAgentWithComplexFunctions() throws {
        let function1JSON = JSON([
            "type": "function",
            "function": [
                "name": "get_stock_price",
                "description": "Get the current stock price",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "symbol": ["type": "string", "description": "The stock symbol, e.g. AAPL"],
                        "currency": ["type": "string", "description": "The currency for the price", "enum": ["USD", "EUR", "GBP"]]
                    ],
                    "required": ["symbol"]
                ]
            ]
        ])
        
        let function2JSON = JSON([
            "type": "function",
            "function": [
                "name": "calculate_mortgage",
                "description": "Calculate monthly mortgage payment",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "principal": ["type": "number", "description": "The loan amount"],
                        "rate": ["type": "number", "description": "Annual interest rate as a percentage"],
                        "term": ["type": "integer", "description": "Loan term in years"]
                    ],
                    "required": ["principal", "rate", "term"]
                ]
            ]
        ])
        
        let agent = Agent(
            name: "FinanceAgent",
            model: "gpt-4",
            instructions: { "You are a financial assistant." },
            functions: JSON([function1JSON, function2JSON]),
            toolChoice: "auto",
            parallelToolCalls: false
        )
        
        // Test encoding
        let encodedData = try JSONEncoder().encode(agent)
        
        // Test decoding
        let decodedAgent = try JSONDecoder().decode(Agent.self, from: encodedData)
        
        // Assertions
        XCTAssertEqual(agent.name, decodedAgent.name)
        XCTAssertEqual(agent.model, decodedAgent.model)
        XCTAssertEqual(agent.instructions, decodedAgent.instructions)
        XCTAssertEqual(agent.toolChoice, decodedAgent.toolChoice)
        XCTAssertEqual(agent.parallelToolCalls, decodedAgent.parallelToolCalls)
        
        // Check functions
        XCTAssertEqual(agent.functions?.arrayValue.count, decodedAgent.functions?.arrayValue.count)
        XCTAssertEqual(agent.functions?.arrayValue[0]["function"]["name"].stringValue, decodedAgent.functions?.arrayValue[0]["function"]["name"].stringValue)
        XCTAssertEqual(agent.functions?.arrayValue[1]["function"]["name"].stringValue, decodedAgent.functions?.arrayValue[1]["function"]["name"].stringValue)
        
        // Check function parameters for both tools
        for i in 0..<2 {
            let originalParams = agent.functions?.arrayValue[i]["function"]["parameters"]
            let decodedParams = decodedAgent.functions?.arrayValue[i]["function"]["parameters"]
            XCTAssertEqual(originalParams?["type"].stringValue, decodedParams?["type"].stringValue)
            XCTAssertEqual(originalParams?["properties"].dictionaryValue.count, decodedParams?["properties"].dictionaryValue.count)
            XCTAssertEqual(originalParams?["required"].arrayValue, decodedParams?["required"].arrayValue)
        }
    }
}
