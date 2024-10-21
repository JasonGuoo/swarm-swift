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
}
