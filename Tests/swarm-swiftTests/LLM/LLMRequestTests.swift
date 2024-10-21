import XCTest
@testable import swarm_swift

final class LLMRequestTests: XCTestCase {
    func testLLMRequestCreation() {
        let messages = [
            LLMMessage(role: "system", content: "You are a helpful assistant."),
            LLMMessage(role: "user", content: "What's the weather like today?")
        ]
        
        let request = LLMRequest(
            model: "gpt-3.5-turbo",
            messages: messages,
            temperature: 0.7,
            maxTokens: 100
        )
        
        XCTAssertEqual(request.model, "gpt-3.5-turbo")
        XCTAssertEqual(request.messages.count, 2)
        XCTAssertEqual(request.messages[0].role, "system")
        XCTAssertEqual(request.messages[0].content, "You are a helpful assistant.")
        XCTAssertEqual(request.messages[1].role, "user")
        XCTAssertEqual(request.messages[1].content, "What's the weather like today?")
        XCTAssertEqual(request.temperature, 0.7)
        XCTAssertEqual(request.maxTokens, 100)
    }
    
    func testLLMRequestFromJSON() {
        let jsonString = """
        {
            "model": "gpt-3.5-turbo",
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "What's the weather like today?"}
            ],
            "temperature": 0.7,
            "max_tokens": 100
        }
        """
        
        do {
            let request = try LLMRequest.fromJSONString(jsonString)
            XCTAssertEqual(request.model, "gpt-3.5-turbo")
            XCTAssertEqual(request.messages.count, 2)
            XCTAssertEqual(request.messages[0].role, "system")
            XCTAssertEqual(request.messages[0].content, "You are a helpful assistant.")
            XCTAssertEqual(request.messages[1].role, "user")
            XCTAssertEqual(request.messages[1].content, "What's the weather like today?")
            XCTAssertEqual(request.temperature, 0.7)
            XCTAssertEqual(request.maxTokens, 100)
        } catch {
            XCTFail("Failed to create LLMRequest from JSON: \(error)")
        }
    }

    func testLLMMessageCreation() {
        let message = LLMMessage(role: "user", content: "Hello, AI!")
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Hello, AI!")
    }

    func testLLMMessageToDictionary() {
        let message = LLMMessage(role: "assistant", content: "How can I help you?")
        do {
            let dict = try message.toDictionary()
            XCTAssertEqual(dict["role"] as? String, "assistant")
            XCTAssertEqual(dict["content"] as? String, "How can I help you?")
        } catch {
            XCTFail("Failed to convert LLMMessage to dictionary: \(error)")
        }
    }
}
