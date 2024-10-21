import XCTest
@testable import swarm_swift

final class AgentTests: XCTestCase {
    func testAgentCreation() {
        let agent = Agent(name: "TestAgent", model:"gpt4o", instructions: {"You are a test agent."})
        XCTAssertEqual(agent.name, "TestAgent")
        XCTAssertEqual(agent.instructions, {"You are a test agent."}())
    }
    
    
    // Add more tests as needed
}
