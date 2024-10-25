import XCTest
import SwiftyJSON
@testable import swarm_swift

final class LLMRequestTests: XCTestCase {
    func testRequestCreation() {
        let request = Request()
        request.withModel(model: "gpt-3.5-turbo")
        
        let systemMessage = Message()
        systemMessage.withRole(role: "system")
        systemMessage.withContent(content: "You are a helpful assistant.")
        request.appendMessage(message: systemMessage)
        
        let userMessage = Message()
        userMessage.withRole(role: "user")
        userMessage.withContent(content: "What's the weather like today?")
        request.appendMessage(message: userMessage)
        
        request.withTemperature(0.7)
        request.withMaxTokens(100)
        
        XCTAssertEqual(request.json["model"].stringValue, "gpt-3.5-turbo")
        XCTAssertEqual(request.json["messages"].arrayValue.count, 2)
        XCTAssertEqual(request.json["messages"][0]["role"].stringValue, "system")
        XCTAssertEqual(request.json["messages"][0]["content"].stringValue, "You are a helpful assistant.")
        XCTAssertEqual(request.json["messages"][1]["role"].stringValue, "user")
        XCTAssertEqual(request.json["messages"][1]["content"].stringValue, "What's the weather like today?")
        XCTAssertEqual(request.json["temperature"].floatValue, 0.7)
        XCTAssertEqual(request.json["max_tokens"].intValue, 100)
    }
    
    func testRequestFromJSON() {
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
        
        let request = Request(parseJSON: jsonString)
        
        XCTAssertEqual(request.json["model"].stringValue, "gpt-3.5-turbo")
        XCTAssertEqual(request.json["messages"].arrayValue.count, 2)
        XCTAssertEqual(request.json["messages"][0]["role"].stringValue, "system")
        XCTAssertEqual(request.json["messages"][0]["content"].stringValue, "You are a helpful assistant.")
        XCTAssertEqual(request.json["messages"][1]["role"].stringValue, "user")
        XCTAssertEqual(request.json["messages"][1]["content"].stringValue, "What's the weather like today?")
        XCTAssertEqual(request.json["temperature"].floatValue, 0.7)
        XCTAssertEqual(request.json["max_tokens"].intValue, 100)
    }

    func testMessageCreation() {
        let message = Message()
        message.withRole(role: "user")
        message.withContent(content: "Hello, AI!")
        
        XCTAssertEqual(message.json["role"].stringValue, "user")
        XCTAssertEqual(message.json["content"].stringValue, "Hello, AI!")
    }

    func testAppendFunction() {
        let request = Request()
        request.appendFunction(
            name: "get_current_weather",
            description: "Get the current weather in a given location",
            parameters: [
                "type": "object",
                "properties": [
                    "location": ["type": "string", "description": "The city and state, e.g. San Francisco, CA"],
                    "unit": ["type": "string", "enum": ["celsius", "fahrenheit"]]
                ],
                "required": ["location"]
            ]
        )
        
        XCTAssertEqual(request.json["tools"].arrayValue.count, 1)
        XCTAssertEqual(request.json["tools"][0]["type"].stringValue, "function")
        XCTAssertEqual(request.json["tools"][0]["function"]["name"].stringValue, "get_current_weather")
        XCTAssertEqual(request.json["tools"][0]["function"]["description"].stringValue, "Get the current weather in a given location")
        XCTAssertEqual(request.json["tools"][0]["function"]["parameters"]["type"].stringValue, "object")
        XCTAssertEqual(request.json["tools"][0]["function"]["parameters"]["properties"]["location"]["type"].stringValue, "string")
        XCTAssertEqual(request.json["tools"][0]["function"]["parameters"]["required"][0].stringValue, "location")
    }
}
