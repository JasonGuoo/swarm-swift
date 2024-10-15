import XCTest
@testable import swarm_swift

class AzureOpenAIClientTests: XCTestCase {
    var client: LLMClient!
    
    override func setUp() {
        super.setUp()
        let config = TestUtils.loadConfig(for: "azureopenai")
        client = ClientFactory.getLLMClient(apiType: "AzureOpenAI", config: config)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testCreateChatCompletion() throws {
        guard let client = client else {
            XCTFail("Failed to initialize Azure Open AI client")
            return
        }
        
        let message = LLMRequest.Message(role: "user", content: "Hello, Azure Open AI!")
        let request = LLMRequest(model: "gpt4o", messages: [message])
        
        let expectation = XCTestExpectation(description: "Chat completion")
        
        var receivedResponse: LLMResponse?
        var receivedError: Error?
        
        client.createChatCompletion(request: request) { result in
            print("Request sent: \(request)") // 打印请求
            switch result {
            case .success(let llmResponse):
                receivedResponse = llmResponse
                print("Response received: \(llmResponse)") // 打印完整响应
                if let httpResponse = llmResponse.httpResponse as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    XCTAssertEqual(httpResponse.statusCode, 200, "Expected HTTP 200 OK")
                } else {
                    print("HTTP Response not available")
                }
            case .failure(let error):
                receivedError = error
                print("Error received: \(error)")
            }
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 30.0)
        
        // Now check the results
        if let error = receivedError {
            XCTFail("Azure Open AI request failed: \(error.localizedDescription)")
        } else if let response = receivedResponse {
            XCTAssertFalse(response.choices.isEmpty, "Response should not be empty")
            print("Azure Open AI response:")
            print("ID: \(response.id)")
            print("Model: \(response.model)")
            print("Choices:")
            for choice in response.choices {
                print("  Content: \(choice.message.content)")
                print("  Finish Reason: \(choice.finishReason ?? "N/A")")
            }
            if let usage = response.usage {
                print("Usage:")
                print("  Prompt Tokens: \(usage.promptTokens)")
                print("  Completion Tokens: \(usage.completionTokens)")
                print("  Total Tokens: \(usage.totalTokens)")
            }
        } else {
            XCTFail("No response or error received")
        }
    }

    func testCreateChatCompletionWithFunctionCall() throws {
        guard let client = client else {
            XCTFail("Failed to initialize Azure Open AI client")
            return
        }
        
        let message = LLMRequest.Message(role: "user", content: "What's the weather like in New York?")
        let function = LLMRequest.Function(
            name: "get_weather",
            description: "Get the current weather in a given location",
            parameters: [
                "type": "object",
                "properties": [
                    "location": ["type": "string", "description": "The city and state, e.g. San Francisco, CA"],
                    "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]]
                ],
                "required": ["location"]
            ]
        )
        let request = LLMRequest(model: "gpt4o", messages: [message], functions: [function])
        
        let expectation = XCTestExpectation(description: "Chat completion with function call")
        
        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertFalse(response.choices.isEmpty, "Response should not be empty")
                if let functionCall = response.choices.first?.message.functionCall {
                    XCTAssertEqual(functionCall.name, "get_weather", "Function name should match")
                    XCTAssertNotNil(functionCall.arguments, "Function arguments should not be nil")
                    // You might want to add more specific assertions about the function call arguments
                } else {
                    XCTFail("Expected a function call in the response")
                }
            case .failure(let error):
                XCTFail("Azure Open AI request failed: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }

    func testCreateChatCompletionWithFunctionCallAndResponse() throws {
        guard let client = client else {
            XCTFail("Failed to initialize Azure Open AI client")
            return
        }
        
        let userMessage = LLMRequest.Message(role: "user", content: "What's the weather like in New York?")
        let functionMessage = LLMRequest.Message(role: "function", content: """
            {"temperature": 22, "unit": "celsius", "description": "Partly cloudy"}
            """, name: "get_weather")
        let function = LLMRequest.Function(
            name: "get_weather",
            description: "Get the current weather in a given location",
            parameters: [
                "type": "object",
                "properties": [
                    "location": ["type": "string", "description": "The city and state, e.g. San Francisco, CA"],
                    "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]]
                ],
                "required": ["location"]
            ]
        )
        let request = LLMRequest(model: "gpt4o", messages: [userMessage, functionMessage], functions: [function])
        
        let expectation = XCTestExpectation(description: "Chat completion with function call and response")
        
        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertFalse(response.choices.isEmpty, "Response should not be empty")
                if let content = response.choices.first?.message.content {
                    XCTAssertTrue(content.contains("22"), "Response should include the temperature")
                    XCTAssertTrue(content.contains("celsius"), "Response should include the unit")
                    XCTAssertTrue(content.contains("Partly cloudy"), "Response should include the weather description")
                } else {
                    XCTFail("Expected a content in the response")
                }
            case .failure(let error):
                XCTFail("Azure Open AI request failed: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
}
