import XCTest
@testable import swarm_swift

class OpenAIClientTests: XCTestCase {
    var client: LLMClient!
    
    override func setUp() {
        super.setUp()
        let config = TestUtils.loadConfig(for: "openai")
        client = ClientFactory.getLLMClient(apiType: "OpenAI", config: config)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testCreateChatCompletion() {
        let expectation = self.expectation(description: "Chat completion")
        
        let request = LLMRequest.create(
            model: "gpt-3.5-turbo",
            messages: [
                ["role":"system","content": "You are a helpful assistant."],
                ["role":"user","content": "What is the capital of France?"]
            ],
            temperature: 0.7,
            maxTokens: 150,
            additionalParameters: ["top_p": 1.0, "frequency_penalty": 0.0, "presence_penalty": 0.0]
        )
        
        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let response):
                print(" ======== Full response: =======")
                print(response)
                print(" ======== End of response =======")
                XCTAssertFalse(response.isEmpty, "Response should not be empty")
//                XCTAssertEqual(response.object, "chat.completion", "Object should be chat.completion")
                XCTAssertNotNil(response.id, "Response should have an ID")
                XCTAssertNotNil(response.created, "Response should have a creation timestamp")
//                XCTAssertEqual(response.model, "gpt-3.5-turbo", "Model should match the request") 
                
                XCTAssertFalse(response.choices?.isEmpty ?? true, "Choices should not be empty")
                if let firstChoice = response.choices?.first {
                    XCTAssertEqual(firstChoice.index, 0, "First choice should have index 0")
                    XCTAssertEqual(firstChoice.message?.role, "assistant", "Message role should be assistant")
                    XCTAssertNotNil(firstChoice.message?.content, "Message should have content")
                    XCTAssertTrue(firstChoice.message?.content?.contains("Paris") ?? false, "Content should mention Paris")
                    XCTAssertEqual(firstChoice.finishReason, "stop", "Finish reason should be 'stop'")
                }
                
                XCTAssertNotNil(response.usage, "Response should include usage information")
                XCTAssertNotNil(response.usage?.promptTokens, "Usage should include prompt tokens")
                XCTAssertNotNil(response.usage?.completionTokens, "Usage should include completion tokens")
                XCTAssertNotNil(response.usage?.totalTokens, "Usage should include total tokens")
                
            case .failure(let error):
                XCTFail("Chat completion failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }

    func testCreateChatCompletionWithFunctionCall() {
        let expectation = self.expectation(description: "Chat completion with function call")
        
        let functions = [
            [
                "name": "get_current_weather",
                "description": "Get the current weather in a given location",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "location": ["type": "string", "description": "The city and state, e.g. San Francisco, CA"],
                        "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]]
                    ],
                    "required": ["location"]
                ]
            ]
        ]
        
        let jsonData: [String: Any] = [
            "model": "gpt-3.5-turbo-0613",
            "messages": [
                ["role": "user", "content": "What's the weather like in Boston?"]
            ],
            "tools": functions,
            "tool_choice": "auto",
            "temperature": 0.7,
            "max_tokens": 150
        ]
        
        let request: LLMRequest
        do {
            request = try LLMRequest.fromJSON(jsonData)
        } catch {
            XCTFail("Failed to create LLMRequest: \(error)")
            return
        }
        
        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertFalse(response.isEmpty, "Response should not be empty")
                XCTAssertNotNil(response.id, "Response should have an ID")
                XCTAssertNotNil(response.created, "Response should have a creation timestamp")
                
                print("================Full LLM Response:=================")
                print(response.description)
                print("================End of LLM Response=================")
                XCTAssertFalse(response.choices?.isEmpty ?? true, "Choices should not be empty")
                if let firstChoice = response.choices?.first {
                    XCTAssertEqual(firstChoice.index, 0, "First choice should have index 0")
                    XCTAssertEqual(firstChoice.message?.role, "assistant", "Message role should be assistant")
                    // XCTAssertNotNil(firstChoice.message?.functionCall, "Message should have a function call")
                    // XCTAssertEqual(firstChoice.message?.functionCall?.name, "get_current_weather", "Function call name should be get_current_weather")
                    // XCTAssertNotNil(firstChoice.message?.functionCall?.arguments, "Function call should have arguments")
                    
                    // if let arguments = firstChoice.message?.functionCall?.arguments {
                    //     XCTAssertTrue(arguments.contains("Boston"), "Arguments should contain Boston")
                    // }
                    
                    XCTAssertEqual(firstChoice.finishReason, "function_call", "Finish reason should be 'function_call'")
                }
                
                XCTAssertNotNil(response.usage, "Response should include usage information")
                
            case .failure(let error):
                XCTFail("Chat completion with function call failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
}
