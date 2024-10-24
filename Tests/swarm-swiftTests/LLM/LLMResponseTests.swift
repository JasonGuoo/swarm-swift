import XCTest
import SwiftyJSON
@testable import swarm_swift

class LLMResponseTests: XCTestCase {
    func testResponseFromJSONWithoutAdditionalFields() {
        let jsonString = """
        {"id":"chatcmpl-AKkxsQq2iWFyQlKzibk5RfInJ7w83","object":"chat.completion","created":1729510456,"model":"gpt-4o-mini","choices":[{"index":0,"message":{"role":"assistant","content":"The capital of France is Paris."},"finish_reason":"stop"}],"usage":{"prompt_tokens":24,"completion_tokens":7,"total_tokens":31}}
        """
        
        let response = Response(parseJSON: jsonString)
        
        XCTAssertEqual(response.getId(), "chatcmpl-AKkxsQq2iWFyQlKzibk5RfInJ7w83")
        XCTAssertEqual(response.getObject(), "chat.completion")
        XCTAssertEqual(response.getCreated(), 1729510456)
        XCTAssertEqual(response.getModel(), "gpt-4o-mini")
        
        XCTAssertEqual(response.getChoicesCount(), 1)
        XCTAssertEqual(response.getChoiceIndex(at: 0), 0)
        XCTAssertEqual(response.getChoiceMessage(at: 0)?["role"].stringValue, "assistant")
        XCTAssertEqual(response.getChoiceMessage(at: 0)?["content"].stringValue, "The capital of France is Paris.")
        XCTAssertEqual(response.getChoiceFinishReason(at: 0), "stop")
        
        XCTAssertEqual(response.getUsagePromptTokens(), 24)
        XCTAssertEqual(response.getUsageCompletionTokens(), 7)
        XCTAssertEqual(response.getUsageTotalTokens(), 31)
    }

    func testResponseFromJSONWithToolCalls() {
        let jsonString = """
        {"choices":[{"finish_reason":"tool_calls","index":0,"message":{"role":"assistant","tool_calls":[{"function":{"arguments":"{\\\"location\\\": \\\"Boston, MA\\\", \\\"unit\\\": \\\"fahrenheit\\\"}","name":"get_current_weather"},"id":"call_9131157062184528331","index":0,"type":"function"}]}}],"created":1729512661,"id":"2024102120110097adab97583348f1","model":"glm-4-flash","request_id":"2024102120110097adab97583348f1","usage":{"completion_tokens":20,"prompt_tokens":207,"total_tokens":227}}
        """
        
        let response = Response(parseJSON: jsonString)
        
        XCTAssertEqual(response.getId(), "2024102120110097adab97583348f1")
        XCTAssertEqual(response.getCreated(), 1729512661)
        XCTAssertEqual(response.getModel(), "glm-4-flash")
        
        XCTAssertEqual(response.getChoicesCount(), 1)
        XCTAssertEqual(response.getChoiceIndex(at: 0), 0)
        XCTAssertEqual(response.getChoiceFinishReason(at: 0), "tool_calls")
        
        let message = response.getChoiceMessage(at: 0)
        XCTAssertEqual(message?["role"].stringValue, "assistant")
        
        XCTAssertEqual(response.getToolCallsCount(at: 0), 1)
        XCTAssertEqual(response.getToolCallId(at: 0, toolCallIndex: 0), "call_9131157062184528331")
        XCTAssertEqual(response.getToolCallType(at: 0, toolCallIndex: 0), "function")
        XCTAssertEqual(response.getToolCallFunctionName(at: 0, toolCallIndex: 0), "get_current_weather")
        XCTAssertEqual(response.getToolCallFunctionArguments(at: 0, toolCallIndex: 0), "{\"location\": \"Boston, MA\", \"unit\": \"fahrenheit\"}")
        
        XCTAssertEqual(response.getUsagePromptTokens(), 207)
        XCTAssertEqual(response.getUsageCompletionTokens(), 20)
        XCTAssertEqual(response.getUsageTotalTokens(), 227)
    }
}
