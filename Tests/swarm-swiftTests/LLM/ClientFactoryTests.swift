import XCTest
import Foundation
@testable import swarm_swift

/**
 ClientFactoryTests

 This test suite is designed to verify the functionality of the ClientFactory class,
 which is responsible for creating various LLM (Language Model) clients based on
 configuration files.

 Setup Instructions:
 1. Create a directory named 'config' in your home directory (~/).
 2. In the project's 'examples' directory, you will find example .env files for each LLM type.
    Copy these files to the ~/config/ directory you created. The files are:
    - .env.openai
    - .env.azureopenai
    - .env.ollama
    - .env.deepseek
    - .env.chatglm

 3. Edit each .env file in the ~/config/ directory, replacing the placeholder values
    with your actual API keys, base URLs, and other required information.
    For example, in .env.openai:
    OpenAI_API_KEY=your_actual_api_key_here
    OpenAI_API_BASE_URL=https://api.openai.com/v1

 4. Ensure that you have the necessary dependencies and LLM client classes implemented
    in your project.

 Running the Tests:
 1. Open your terminal and navigate to the root directory of your Swift package.
 2. Run the following command to execute all tests:
    swift test

 3. To run a specific test, use:
    swift test --filter ClientFactoryTests/testMethodName

 Note: These tests will attempt to create actual LLM clients based on your configuration.
 Ensure that you have valid API keys and permissions before running the tests.

 If a test fails, check the console output for detailed information about the failure,
 including whether the .env file was found and its contents.
 */

final class ClientFactoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testGetLLMClient() {
        let apiTypes = ["OpenAI", "AzureOpenAI", "Ollama", "DeepSeek", "ChatGLM"]
        
        for apiType in apiTypes {
            print("\n--- Testing \(apiType) ---")
            let config = TestUtils.loadConfig(for: apiType)
            let client = ClientFactory.getLLMClient(apiType: apiType, config: config)
            
            if let client = client {
                XCTAssertNotNil(client, "Successfully created client for \(apiType)")
                print("Successfully created client for \(apiType)")
                
                switch apiType {
                case "OpenAI":
                    XCTAssertTrue(client is OpenAIClient)
                case "AzureOpenAI":
                    XCTAssertTrue(client is AzureOpenAIClient)
                case "Ollama":
                    XCTAssertTrue(client is OllamaClient)
                case "DeepSeek":
                    XCTAssertTrue(client is DeepSeekClient)
                case "ChatGLM":
                    XCTAssertTrue(client is ChatGLMClient)
                default:
                    XCTFail("Unexpected API type: \(apiType)")
                }
            } else {
                XCTFail("Failed to create client for \(apiType)")
                print("Failed to create client for \(apiType)")
            }
        }
    }
    
    func testGetLLMClientWithNoConfig() {
        print("\n--- Testing with no config ---")
        XCTAssertNil(ClientFactory.getLLMClient(apiType: "OpenAI", config: nil))
        print("Successfully returned nil for null config")
    }
    
    func testGetLLMClientWithDefaultApiType() {
        print("\n--- Testing with default API type ---")
        let config = TestUtils.loadConfig(for: "OpenAI")
        let client = ClientFactory.getLLMClient(config: config)
        XCTAssertTrue(client is OpenAIClient)
        print("Successfully created OpenAIClient with default API type")
    }
    
    func testGetLLMClientWithInvalidApiType() {
        print("\n--- Testing with invalid API type ---")
        let config = TestUtils.loadConfig(for: "OpenAI")
        let client = ClientFactory.getLLMClient(apiType: "InvalidAPI", config: config)
        XCTAssertTrue(client is OpenAIClient)
        print("Successfully fell back to OpenAIClient for invalid API type")
    }
}
