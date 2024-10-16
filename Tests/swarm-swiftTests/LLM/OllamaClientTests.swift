import XCTest
@testable import swarm_swift

class OllamaClientTests: XCTestCase {
    var client: LLMClient!
    
    override func setUp() {
        super.setUp()
        let config = TestUtils.loadConfig(for: "ollama")
        client = ClientFactory.getLLMClient(apiType: "Ollama", config: config)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testCreateChatCompletion() async throws {
        
    }
}
