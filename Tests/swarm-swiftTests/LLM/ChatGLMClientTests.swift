import XCTest
@testable import swarm_swift

class ChatGLMClientTests: XCTestCase {
    var client: LLMClient!
    
    override func setUp() {
        super.setUp()
        let config = TestUtils.loadConfig(for: "chatglm")
        client = ClientFactory.getLLMClient(apiType: "ChatGLM", config: config)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testCreateChatCompletion() {
        let expectation = self.expectation(description: "Chat completion")
        
        let request = LLMRequest.create(
            model: ChatGLMClient.ModelType.glm4Flash.rawValue,  // 使用适合 ChatGLM 的模型名称
            messages: [
                LLMMessage(role: "system", content: "You are a helpful assistant.", additionalFields: [:]),
                LLMMessage(role: "user", content: "What is the capital of France?",  additionalFields: [:])
            ],
            temperature: 0.7,
            maxTokens: 150,
            additionalParameters: [
                "top_p": AnyCodable(1.0),
                "frequency_penalty": AnyCodable(0.0),
                "presence_penalty": AnyCodable(0.0)
            ]
        )
        
        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let response):
                print(" ======== Full response: =======")
                print(response)
                print(" ======== End of response =======")
                XCTAssertFalse(response.isEmpty, "Response should not be empty")
                XCTAssertNotNil(response.id, "Response should have an ID")
                XCTAssertNotNil(response.created, "Response should have a creation timestamp")
                
                XCTAssertFalse(response.choices?.isEmpty ?? true, "Choices should not be empty")
                if let firstChoice = response.choices?.first {
                    XCTAssertEqual(firstChoice.index, 0, "First choice should have index 0")
                    XCTAssertEqual(firstChoice.message?.role, "assistant", "Message role should be assistant")
                    XCTAssertNotNil(firstChoice.message?.content, "Message should have content")
                    XCTAssertTrue(firstChoice.message?.content.contains("Paris") ?? false, "Content should mention Paris")
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
        
        waitForExpectations(timeout: 30, handler: nil)
    }

    func testCreateChatCompletionWithFunctionCall() {
        let expectation = self.expectation(description: "Chat completion with function call")
        
        let jsonstring:String = """
        {
          "model": "glm-4-flash",
          "messages": [
            {
              "role": "user",
              "content": "What's the weather like in Boston today?"
            }
          ],
          "tools": [
            {
              "type": "function",
              "function": {
                "name": "get_current_weather",
                "description": "Get the current weather in a given location",
                "parameters": {
                  "type": "object",
                  "properties": {
                    "location": {
                      "type": "string",
                      "description": "The city and state, e.g. San Francisco, CA"
                    },
                    "unit": {
                      "type": "string",
                      "enum": ["celsius", "fahrenheit"]
                    }
                  },
                  "required": ["location"]
                }
              }
            }
          ],
          "tool_choice": "auto"
        }
        """
        
        let request: LLMRequest
        do {
            request = try LLMRequest.fromJSONString(jsonstring)
            DebugUtils.printDebug(request.description)
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
                }
                
                XCTAssertNotNil(response.usage, "Response should include usage information")
                
            case .failure(let error):
                XCTFail("Chat completion with function call failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
}
