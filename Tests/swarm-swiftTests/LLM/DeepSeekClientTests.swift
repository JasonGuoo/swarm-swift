import XCTest
@testable import swarm_swift

class DeepSeekClientTests: XCTestCase {
    var client: LLMClient!
    
    override func setUp() {
        super.setUp()
        let config = TestUtils.loadConfig(for: "deepseek")
        client = ClientFactory.getLLMClient(apiType: "DeepSeek", config: config)
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
}
