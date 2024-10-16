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
    
}
