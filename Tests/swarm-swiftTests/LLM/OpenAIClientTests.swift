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
    
    func testCreateChatCompletion() async throws {
        guard let client = client else {
            XCTFail("Failed to initialize OpenAI client")
            return
        }
        
        let message = LLMRequest.Message(role: "user", content: "Hello, OpenAI!")
        let request = LLMRequest(model: "gpt-3.5-turbo", messages: [message])
        
        do {
            let response = try await client.createChatCompletion(request: request) { result in
                switch result {
                case .success(let llmResponse):
                    XCTAssertFalse(llmResponse.choices.isEmpty, "Response should not be empty")
                    print("OpenAI response:")
                    print("ID: \(llmResponse.id)")
                    print("Model: \(llmResponse.model)")
                    print("Choices:")
                    for choice in llmResponse.choices {
                        print("  Content: \(choice.message.content)")
                        print("  Finish Reason: \(choice.finishReason ?? "N/A")")
                    }
                    if let usage = llmResponse.usage {
                        print("Usage:")
                        print("  Prompt Tokens: \(usage.promptTokens)")
                        print("  Completion Tokens: \(usage.completionTokens)")
                        print("  Total Tokens: \(usage.totalTokens)")
                    }
                case .failure(let error):
                    XCTFail("OpenAI request failed: \(error.localizedDescription)")
                }
            }
            XCTAssertNotNil(response)
        } catch let error as LLMError {
            XCTFail("LLMError: \(error.localizedDescription)")
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription)")
        }
    }
}
