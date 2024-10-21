import XCTest
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
//        XCTAssertEqual(decodedAgent.instructions, ()->{""})
    }
    
    
    func testAgentDecodingCustomDateFormat() throws {
        let jsonString = """
        {
            "name": "DateAgent",
            "model": "gpt3",
            "instructions": "Time-sensitive agent",
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let decodedAgent = try decoder.decode(Agent.self, from: jsonData)
        
        XCTAssertEqual(decodedAgent.name, "DateAgent")
        XCTAssertEqual(decodedAgent.model, "gpt3")
        XCTAssertEqual(decodedAgent.instructions, "Time-sensitive agent")
//        XCTAssertEqual(decodedAgent.createdAt, dateFormatter.date(from: "2023-04-01T12:00:00+0000"))
        XCTAssertEqual(decodedAgent.parallelToolCalls, true)
    }
    
    
    func testAgentEncodingDecoding() throws {
        let tool = LLMRequest.Tool(
            type: "function",
            function: LLMRequest.Function(
                name: "get_weather",
                description: "Get the current weather",
                parameters: LLMRequest.Parameters(
                    type: "object",
                    properties: [
                        "location": LLMRequest.Property(type: "string", description: "The city and state, e.g. San Francisco, CA"),
                        "unit": LLMRequest.Property(type: "string", description: "The temperature unit", enum: ["celsius", "fahrenheit"])
                    ],
                    required: ["location"]
                )
            )
        )
        
        let agent = Agent(
            name: "WeatherAgent",
            model: "gpt-4",
            instructions: { "You are a weather assistant." },
            functions: [tool],
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
        XCTAssertEqual(agent.functions?.count, decodedAgent.functions?.count)
        XCTAssertEqual(agent.functions?[0].type, decodedAgent.functions?[0].type)
        XCTAssertEqual(agent.functions?[0].function.name, decodedAgent.functions?[0].function.name)
        XCTAssertEqual(agent.functions?[0].function.description, decodedAgent.functions?[0].function.description)
        
        // Check function parameters
        let originalParams = agent.functions?[0].function.parameters
        let decodedParams = decodedAgent.functions?[0].function.parameters
        XCTAssertEqual(originalParams?.type, decodedParams?.type)
        XCTAssertEqual(originalParams?.properties.count, decodedParams?.properties.count)
        XCTAssertEqual(originalParams?.required, decodedParams?.required)
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
        XCTAssertEqual(decodedAgent.instructions, {"You are a helpful agent."}())
        XCTAssertNil(decodedAgent.functions)
        XCTAssertEqual(decodedAgent.toolChoice, "auto")
        XCTAssertEqual(decodedAgent.parallelToolCalls, true) // Default value
    }
    
    func testAgentWithComplexFunctions() throws {
        let tool1 = LLMRequest.Tool(
            type: "function",
            function: LLMRequest.Function(
                name: "get_stock_price",
                description: "Get the current stock price",
                parameters: LLMRequest.Parameters(
                    type: "object",
                    properties: [
                        "symbol": LLMRequest.Property(type: "string", description: "The stock symbol, e.g. AAPL"),
                        "currency": LLMRequest.Property(type: "string", description: "The currency for the price", enum: ["USD", "EUR", "GBP"])
                    ],
                    required: ["symbol"]
                )
            )
        )
        
        let tool2 = LLMRequest.Tool(
            type: "function",
            function: LLMRequest.Function(
                name: "calculate_mortgage",
                description: "Calculate monthly mortgage payment",
                parameters: LLMRequest.Parameters(
                    type: "object",
                    properties: [
                        "principal": LLMRequest.Property(type: "number", description: "The loan amount"),
                        "rate": LLMRequest.Property(type: "number", description: "Annual interest rate as a percentage"),
                        "term": LLMRequest.Property(type: "integer", description: "Loan term in years")
                    ],
                    required: ["principal", "rate", "term"]
                )
            )
        )
        
        let agent = Agent(
            name: "FinanceAgent",
            model: "gpt-4",
            instructions: { "You are a financial assistant." },
            functions: [tool1, tool2],
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
        XCTAssertEqual(agent.functions?.count, decodedAgent.functions?.count)
        XCTAssertEqual(agent.functions?[0].function.name, decodedAgent.functions?[0].function.name)
        XCTAssertEqual(agent.functions?[1].function.name, decodedAgent.functions?[1].function.name)
        
        // Check function parameters for both tools
        for i in 0..<2 {
            let originalParams = agent.functions?[i].function.parameters
            let decodedParams = decodedAgent.functions?[i].function.parameters
            XCTAssertEqual(originalParams?.type, decodedParams?.type)
            XCTAssertEqual(originalParams?.properties.count, decodedParams?.properties.count)
            XCTAssertEqual(originalParams?.required, decodedParams?.required)
        }
    }
}
