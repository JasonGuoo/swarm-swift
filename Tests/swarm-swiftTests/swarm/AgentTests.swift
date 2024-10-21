import XCTest
@testable import swarm_swift

final class AgentTests: XCTestCase {
    func testAgentCreation() {
        let agent = Agent(name: "TestAgent", systemPrompt: "You are a test agent.")
        XCTAssertEqual(agent.name, "TestAgent")
        XCTAssertEqual(agent.systemPrompt, "You are a test agent.")
    }
    
    func testAgentAddMessage() {
        var agent = Agent(name: "TestAgent", systemPrompt: "You are a test agent.")
        agent.addMessage(role: "user", content: "Hello, agent!")
        XCTAssertEqual(agent.messages.count, 1)
        XCTAssertEqual(agent.messages[0].role, "user")
        XCTAssertEqual(agent.messages[0].content, "Hello, agent!")
    }
    
    // Add more tests as needed
}
