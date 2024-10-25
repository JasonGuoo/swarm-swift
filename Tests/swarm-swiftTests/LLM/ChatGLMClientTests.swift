import XCTest
import SwiftyJSON
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
        
        let request = Request()
        request.withModel(model: ChatGLMClient.ModelType.glm4Flash.rawValue)
        
        let systemMessage = Message()
        systemMessage.withRole(role: "system")
        systemMessage.withContent(content: "You are a helpful assistant.")
        request.appendMessage(message: systemMessage)
        
        let userMessage = Message()
        userMessage.withRole(role: "user")
        userMessage.withContent(content: "What is the capital of France?")
        request.appendMessage(message: userMessage)
        
        request.withTemperature(0.7)
        request.withMaxTokens(150)
        
        print("request: \(request.json.rawString())")
        
        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let response):
                print(" ======== Full response: =======")
                print(response.description)
                print(" ======== End of response =======")
                XCTAssertFalse(response.isEmpty, "Response should not be empty")
                XCTAssertNotNil(response.getId(), "Response should have an ID")
                XCTAssertNotNil(response.getCreated(), "Response should have a creation timestamp")
                
                XCTAssertGreaterThan(response.getChoicesCount(), 0, "Choices should not be empty")
                if let firstChoice = response.getChoiceMessage(at: 0) {
                    XCTAssertEqual(firstChoice["role"].stringValue, "assistant", "Message role should be assistant")
                    XCTAssertNotNil(firstChoice["content"].string, "Message should have content")
                    XCTAssertTrue(firstChoice["content"].stringValue.contains("Paris"), "Content should mention Paris")
                }
                
                XCTAssertNotNil(response.getUsage(), "Response should include usage information")
                XCTAssertNotNil(response.getUsagePromptTokens(), "Usage should include prompt tokens")
                XCTAssertNotNil(response.getUsageCompletionTokens(), "Usage should include completion tokens")
                XCTAssertNotNil(response.getUsageTotalTokens(), "Usage should include total tokens")
                
            case .failure(let error):
                XCTFail("Chat completion failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }

    func testCreateChatCompletionWithFunctionCall() {
        let expectation = self.expectation(description: "Chat completion with function call")
        
        let jsonString = """
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
        
        let request = Request(parseJSON: jsonString)
        
        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertFalse(response.isEmpty, "Response should not be empty")
                XCTAssertNotNil(response.getId(), "Response should have an ID")
                XCTAssertNotNil(response.getCreated(), "Response should have a creation timestamp")
                
                print("================Full LLM Response:=================")
                print(response.description)
                print("================End of LLM Response=================")
                
                XCTAssertGreaterThan(response.getChoicesCount(), 0, "Choices should not be empty")
                if let firstChoice = response.getChoiceMessage(at: 0) {
                    XCTAssertEqual(firstChoice["role"].stringValue, "assistant", "Message role should be assistant")
                    
                    // Check for tool calls
                    let toolCalls = firstChoice["tool_calls"].arrayValue
                    XCTAssertFalse(toolCalls.isEmpty, "Tool calls should not be empty")
                    
                    if let firstToolCall = toolCalls.first {
                        XCTAssertEqual(firstToolCall["function"]["name"].stringValue, "get_current_weather", "Function call name should be get_current_weather")
                        XCTAssertNotNil(firstToolCall["function"]["arguments"].string, "Function call should have arguments")
                        
                        if let arguments = firstToolCall["function"]["arguments"].string {
                            XCTAssertTrue(arguments.contains("Boston"), "Arguments should contain Boston")
                        }
                    }
                }
                
                XCTAssertNotNil(response.getUsage(), "Response should include usage information")
                
            case .failure(let error):
                XCTFail("Chat completion with function call failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
}
