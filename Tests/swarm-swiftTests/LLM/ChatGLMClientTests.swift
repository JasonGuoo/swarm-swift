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
    
    func testCreateChatCompletion() throws {
        
    }

    func testCreateChatCompletionWithFunctionCall() throws {
        
    }
}
