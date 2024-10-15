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
            switch result {
            case .success(let llmResponse):
                receivedResponse = llmResponse
            case .failure(let error):
                receivedError = error
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
}
