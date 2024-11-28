import XCTest
@testable import swarm_swift

final class OllamaClientTests: XCTestCase {
    var client: OllamaClient!
    
    override func setUp() {
        super.setUp()
        // Using default values for testing
        client = OllamaClient()
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testInitialization() {
        // Test default initialization
        XCTAssertEqual(client.baseURL, "http://localhost:11434/v1")
        XCTAssertEqual(client.apiKey, "ollama")
        XCTAssertEqual(client.modelName, "llama3")
        
        // Test custom initialization
        let customClient = OllamaClient(apiKey: "custom-key", baseURL: "http://custom-url", modelName: "custom-model")
        XCTAssertEqual(customClient.baseURL, "http://custom-url")
        XCTAssertEqual(customClient.apiKey, "custom-key")
        XCTAssertEqual(customClient.modelName, "custom-model")
    }
    
    func testCreateChatCompletion() {
        let expectation = XCTestExpectation(description: "Chat completion")
        
        let request = Request()
        request.appendMessages(messages: [
            Message().withRole(role: "user").withContent(content: "Hello!")
        ])
        
        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let response):
                // Verify response structure
                XCTAssertNotNil(response.json["choices"].array)
                XCTAssertFalse(response.json["choices"].arrayValue.isEmpty)
                
                // Extract and verify content from the response
                if let firstChoice = response.json["choices"].array?.first,
                   let content = firstChoice["message"]["content"].string {
                    XCTAssertFalse(content.isEmpty, "Response content should not be empty")
                    print("Response content: \(content)")
                } else {
                    XCTFail("Failed to extract content from response")
                }
                
                // Check if model was automatically set
                let requestData = try? request.rawData()
                let requestJson = try? JSONSerialization.jsonObject(with: requestData ?? Data(), options: []) as? [String: Any]
                XCTAssertEqual(requestJson?["model"] as? String, "llama3")
                
            case .failure(let error):
                XCTFail("Chat completion failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testCreateCompletion() {
        let expectation = XCTestExpectation(description: "Text completion")
        
        let request = Request()
        request.appendMessages(messages: [
            Message().withRole(role: "user").withContent(content: "Complete this: The quick brown")
        ])
        
        client.createCompletion(request: request) { result in
            switch result {
            case .success(let response):
                // Verify response structure
                XCTAssertNotNil(response.json["choices"].array)
                XCTAssertFalse(response.json["choices"].arrayValue.isEmpty)
                
                // Extract and verify content from the response
                if let firstChoice = response.json["choices"].array?.first,
                   let content = firstChoice["message"]["content"].string {
                    XCTAssertFalse(content.isEmpty, "Response content should not be empty")
                    print("Response content: \(content)")
                } else {
                    XCTFail("Failed to extract content from response")
                }
                
                // Check if model was automatically set
                let requestData = try? request.rawData()
                let requestJson = try? JSONSerialization.jsonObject(with: requestData ?? Data(), options: []) as? [String: Any]
                XCTAssertEqual(requestJson?["model"] as? String, "llama3")
                
            case .failure(let error):
                XCTFail("Text completion failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testModelOverride() {
        let request = Request()
        request.withModel(model: "custom-model")
        request.appendMessages(messages: [
            Message().withRole(role: "user").withContent(content: "Hello!")
        ])
        
        // Verify that the model isn't overridden when explicitly set
        client.createChatCompletion(request: request) { _ in }
        
        let requestData = try? request.rawData()
        let requestJson = try? JSONSerialization.jsonObject(with: requestData ?? Data(), options: []) as? [String: Any]
        XCTAssertEqual(requestJson?["model"] as? String, "custom-model")
    }
    
    func testErrorHandling() {
        let expectation = XCTestExpectation(description: "Error handling")
        
        // Create client with invalid URL to test error handling
        let invalidClient = OllamaClient(baseURL: "invalid-url")
        let request = Request()
        request.appendMessages(messages: [
            Message().withRole(role: "user").withContent(content: "Hello!")
        ])
        
        invalidClient.createChatCompletion(request: request) { result in
            switch result {
            case .success:
                XCTFail("Expected error but got success")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
