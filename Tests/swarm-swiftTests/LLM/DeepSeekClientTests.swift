import XCTest
import SwiftyJSON
@testable import swarm_swift

class DeepSeekClientTests: XCTestCase {
    var client: LLMClient!
    var config: Config!
    
    override func setUp() {
        super.setUp()
        config = TestUtils.loadConfig(for: "deepseek")
        client = ClientFactory.getLLMClient(apiType: "DeepSeek", config: config)
    }
    
    override func tearDown() {
        client = nil
        config = nil
        super.tearDown()
    }
    
    func testCreateChatCompletion() {
        let expectation = self.expectation(description: "Chat completion")
        
        let request = Request()
        request.withModel(model: config.value(forKey: "DeepSeek_MODEL_NAME") ?? "deepseek-chat")
        
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
    
    func testCreateCompletion() {
        let expectation = self.expectation(description: "Text completion")
        
        let request = Request()
        request.withModel(model: config.value(forKey: "DeepSeek_MODEL_NAME") ?? "deepseek-chat")
        
        let userMessage = Message()
        userMessage.withRole(role: "user")
        userMessage.withContent(content: "Complete this sentence: The capital of France is")
        request.appendMessage(message: userMessage)
        
        request.withTemperature(0.7)
        request.withMaxTokens(50)
        
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
                    XCTAssertNotNil(firstChoice["content"].string, "Message should have content")
                    XCTAssertTrue(firstChoice["content"].stringValue.contains("Paris"), "Content should mention Paris")
                }
                
                XCTAssertNotNil(response.getUsage(), "Response should include usage information")
                XCTAssertNotNil(response.getUsagePromptTokens(), "Usage should include prompt tokens")
                XCTAssertNotNil(response.getUsageCompletionTokens(), "Usage should include completion tokens")
                XCTAssertNotNil(response.getUsageTotalTokens(), "Usage should include total tokens")
                
            case .failure(let error):
                XCTFail("Text completion failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testUnsupportedOperations() {
        let request = Request()
        let expectation1 = self.expectation(description: "Embedding creation")
        let expectation2 = self.expectation(description: "Image creation")
        let expectation3 = self.expectation(description: "Transcription")
        
        // Test embedding creation (should fail)
        client.createEmbedding(request: request) { result in
            switch result {
            case .success:
                XCTFail("Embedding creation should not be supported")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("not supported"), "Error should indicate operation is not supported")
            }
            expectation1.fulfill()
        }
        
        // Test image creation (should fail)
        client.createImage(request: request) { result in
            switch result {
            case .success:
                XCTFail("Image creation should not be supported")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("not supported"), "Error should indicate operation is not supported")
            }
            expectation2.fulfill()
        }
        
        // Test transcription (should fail)
        client.createTranscription(request: request) { result in
            switch result {
            case .success:
                XCTFail("Transcription should not be supported")
            case .failure(let error):
                XCTAssertTrue(error.localizedDescription.contains("not supported"), "Error should indicate operation is not supported")
            }
            expectation3.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}
