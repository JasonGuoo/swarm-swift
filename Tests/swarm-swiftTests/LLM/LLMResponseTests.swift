import XCTest
@testable import swarm_swift

class LLMResponseTests: XCTestCase {
    func testLLMResponseFromJSONWithoutAdditionalFields() {
        let jsonString = """
        {"id":"chatcmpl-AKkxsQq2iWFyQlKzibk5RfInJ7w83","object":"chat.completion","created":1729510456,"model":"gpt-4o-mini","choices":[{"index":0,"message":{"role":"assistant","content":"The capital of France is Paris."},"finish_reason":"stop"}],"usage":{"prompt_tokens":24,"completion_tokens":7,"total_tokens":31}}
        """
        
        let result = LLMResponse.fromJSON(jsonString)
        
        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "chatcmpl-AKkxsQq2iWFyQlKzibk5RfInJ7w83")
            XCTAssertEqual(response.object, "chat.completion")
            XCTAssertEqual(response.created, 1729510456)
            XCTAssertEqual(response.model, "gpt-4o-mini")
            
            XCTAssertEqual(response.choices?.count, 1)
            XCTAssertEqual(response.choices?[0].index, 0)
            XCTAssertEqual(response.choices?[0].message?.role, "assistant")
            XCTAssertEqual(response.choices?[0].message?.content, "The capital of France is Paris.")
            XCTAssertNil(response.choices?[0].message?.additionalFields)
            XCTAssertEqual(response.choices?[0].finishReason, "stop")
            
            XCTAssertEqual(response.usage?.promptTokens, 24)
            XCTAssertEqual(response.usage?.completionTokens, 7)
            XCTAssertEqual(response.usage?.totalTokens, 31)
            
        case .failure(let error):
            XCTFail("Failed to create LLMResponse from JSON: \(error)")
        }
    }

    func testLLMResponseFromJSONWithAdditionalFields() {
        let jsonString = """
        {"id":"chatcmpl-XYZ123","object":"chat.completion","created":1729510457,"model":"gpt-4","choices":[{"index":0,"message":{"role":"assistant","content":"Hello, how can I assist you?","additionalFields":{"importance":"high"}},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":8,"total_tokens":18}}
        """
        
        let result = LLMResponse.fromJSON(jsonString)
        
        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "chatcmpl-XYZ123")
            XCTAssertEqual(response.object, "chat.completion")
            XCTAssertEqual(response.created, 1729510457)
            XCTAssertEqual(response.model, "gpt-4")
            
            XCTAssertEqual(response.choices?.count, 1)
            XCTAssertEqual(response.choices?[0].index, 0)
            XCTAssertEqual(response.choices?[0].message?.role, "assistant")
            XCTAssertEqual(response.choices?[0].message?.content, "Hello, how can I assist you?")
            XCTAssertEqual(response.choices?[0].message?.additionalFields?["importance"]?.value as? String, "high")
            XCTAssertEqual(response.choices?[0].finishReason, "stop")
            
            XCTAssertEqual(response.usage?.promptTokens, 10)
            XCTAssertEqual(response.usage?.completionTokens, 8)
            XCTAssertEqual(response.usage?.totalTokens, 18)
            
        case .failure(let error):
            XCTFail("Failed to create LLMResponse from JSON: \(error)")
        }
    }

    func testLLMResponseFromJSONWithToolCalls() {
        let jsonString = """
        {"choices":[{"finish_reason":"tool_calls","index":0,"message":{"role":"assistant","tool_calls":[{"function":{"arguments":"{\\\"location\\\": \\\"Boston, MA\\\", \\\"unit\\\": \\\"fahrenheit\\\"}","name":"get_current_weather"},"id":"call_9131157062184528331","index":0,"type":"function"}]}}],"created":1729512661,"id":"2024102120110097adab97583348f1","model":"glm-4-flash","request_id":"2024102120110097adab97583348f1","usage":{"completion_tokens":20,"prompt_tokens":207,"total_tokens":227}}
        """
        
        let result = LLMResponse.fromJSON(jsonString)
        
        switch result {
        case .success(let response):
            XCTAssertEqual(response.id, "2024102120110097adab97583348f1")
            XCTAssertEqual(response.created, 1729512661)
            XCTAssertEqual(response.model, "glm-4-flash")

            
            XCTAssertEqual(response.choices?.count, 1)
            XCTAssertEqual(response.choices?[0].index, 0)
            XCTAssertEqual(response.choices?[0].finishReason, "tool_calls")
            
            let message = response.choices?[0].message
            XCTAssertEqual(message?.role, "assistant")
            XCTAssertEqual(message?.content, "")
            
            XCTAssertEqual(response.usage?.promptTokens, 207)
            XCTAssertEqual(response.usage?.completionTokens, 20)
            XCTAssertEqual(response.usage?.totalTokens, 227)
            
        case .failure(let error):
            XCTFail("Failed to create LLMResponse from JSON: \(error)")
        }
    }
}
