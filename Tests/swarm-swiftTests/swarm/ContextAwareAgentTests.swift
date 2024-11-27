import XCTest
import SwiftyJSON
@testable import swarm_swift

final class ContextAwareAgentTests: XCTestCase {
    var agent: ContextAwareAgent!
    var swarm: Swarm!
    var config: Config!
    
    override func setUp() {
        super.setUp()
        agent = ContextAwareAgent()
        
        // Initialize OpenAI client using TestUtils
        config = TestUtils.loadConfig(for: "openai")
        let client = ClientFactory.getLLMClient(apiType: "OpenAI", config: config)!
        swarm = Swarm(client: client)
    }
    
    override func tearDown() {
        agent = nil
        swarm = nil
        config = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testAgentInitialization() {
        XCTAssertEqual(agent.name, "ContextAwareAgent")
        XCTAssertNil(agent.model)  // Model should be nil by default
        XCTAssertNotNil(agent.functions)
        
        // Verify function definition
        let functions = agent.functions?.arrayValue ?? []
        XCTAssertEqual(functions.count, 1)
        
        let function = functions[0]["function"]
        XCTAssertEqual(function["name"].stringValue, "process_with_context")
        XCTAssertTrue(function["description"].stringValue.contains("Process data"))
    }
    
    func testContextProcessing() throws {
        print("\n=== Testing Context Processing ===")
        
        // Prepare test context
        let contextVariables: [String: String] = [
            "user_id": "test_user_123",
            "session_id": "test_session_456",
            "custom_data": "test_value"
        ]
        
        // Create test message
        let message = Message()
            .withRole(role: "user")
            .withContent(content: "Process this test data with context")
        
        // Run the agent
        let result = swarm.run(
            agent: agent,
            messages: [message],
            contextVariables: contextVariables
        )
        
        print("\nResult from testContextProcessing:")
        print("Messages:", result.messages?.map { $0.json.rawString() ?? "" } ?? "nil")
        print("Context Variables:", result.contextVariables ?? [:])
        print("Agent Model:", result.agent?.model ?? "nil")
        print("================================\n")
        
        // Verify results
        XCTAssertNotNil(result.messages)
        XCTAssertFalse(result.messages?.isEmpty ?? true)
        
        // Find function response
        let functionMessages = result.messages?.filter {
            $0.json["role"].stringValue == "function"
        }
        
        XCTAssertNotNil(functionMessages)
        XCTAssertFalse(functionMessages?.isEmpty ?? true)
        
        if let content = functionMessages?.first?.json["content"].string {
            // Verify context values are present in response
            XCTAssertTrue(content.contains("test_user_123"))
            XCTAssertTrue(content.contains("test_session_456"))
            XCTAssertTrue(content.contains("test_value"))
        } else {
            XCTFail("Function message content not found")
        }
    }
    
    func testMissingContext() throws {
        print("\n=== Testing Missing Context ===")
        
        // Run without context
        let message = Message()
            .withRole(role: "user")
            .withContent(content: "Process this data without any context")
        
        let result = swarm.run(
            agent: agent,
            messages: [message],
            contextVariables: [:]  // Empty context
        )
        
        print("\nResult from testMissingContext:")
        print("Messages:", result.messages?.map { $0.json.rawString() ?? "" } ?? "nil")
        print("Context Variables:", result.contextVariables ?? [:])
        print("Agent Model:", result.agent?.model ?? "nil")
        print("================================\n")
        
        // Verify default values are used
        let functionMessages = result.messages?.filter {
            $0.json["role"].stringValue == "function"
        }
        
        if let content = functionMessages?.first?.json["content"].string {
            XCTAssertTrue(content.contains("unknown"))  // Default user_id
            XCTAssertTrue(content.contains("no-session"))  // Default session_id
        } else {
            XCTFail("Function message content not found")
        }
    }
    
    func testContextModification() throws {
        print("\n=== Testing Context Modification ===")
        
        // Test that context doesn't change unexpectedly
        let originalContext = [
            "user_id": "original_user",
            "test_key": "test_value"
        ]
        
        let message = Message()
            .withRole(role: "user")
            .withContent(content: "Process this data with original context")
        
        let result = swarm.run(
            agent: agent,
            messages: [message],
            contextVariables: originalContext
        )
        
        print("\nResult from testContextModification:")
        print("Messages:", result.messages?.map { $0.json.rawString() ?? "" } ?? "nil")
        print("Context Variables:", result.contextVariables ?? [:])
        print("Agent Model:", result.agent?.model ?? "nil")
        print("================================\n")
        
        // Verify context hasn't been modified unexpectedly
        XCTAssertEqual(result.contextVariables?["user_id"], originalContext["user_id"])
        XCTAssertEqual(result.contextVariables?["test_key"], originalContext["test_key"])
    }
    
    func testDirectFunctionCall() throws {
        print("\n=== Testing Direct Function Call ===")
        
        // Test direct function call with context
        let args: [String: Any] = [
            "input_data": "direct test data",
            "_context": [
                "user_id": "direct_user",
                "session_id": "direct_session"
            ]
        ]
        
        let result = agent.process_with_context(args)
        XCTAssertNotNil(result)
        
        // Decode and verify result
        let swarmResult = try JSONDecoder().decode(SwarmResult.self, from: result)
        
        print("\nResult from testDirectFunctionCall:")
        print("Messages:", swarmResult.messages?.map { $0.json.rawString() ?? "" } ?? "nil")
        print("Context Variables:", swarmResult.contextVariables ?? [:])
        print("Agent Model:", swarmResult.agent?.model ?? "nil")
        print("================================\n")
        
        let content = swarmResult.messages?.first?.json["content"].string
        XCTAssertNotNil(content)
        XCTAssertTrue(content?.contains("direct_user") ?? false)
        XCTAssertTrue(content?.contains("direct_session") ?? false)
    }
}
