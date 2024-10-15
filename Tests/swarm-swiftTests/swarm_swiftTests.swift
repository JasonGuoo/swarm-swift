import XCTest
@testable import swarm_swift

final class swarm_swiftTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swarm_swift().text, "Hello, World!")
    }
    
    func testClientFactory() throws {
        // Create an instance of ClientFactoryTests
        let clientFactoryTests = ClientFactoryTests()
        
        // Run the setup method
        clientFactoryTests.setUp()
        
        // Run individual test methods
        clientFactoryTests.testGetLLMClient()
        clientFactoryTests.testGetLLMClientWithNoConfig()
        clientFactoryTests.testGetLLMClientWithDefaultApiType()
        clientFactoryTests.testGetLLMClientWithInvalidApiType()
        
        // Run the tearDown method if needed
        clientFactoryTests.tearDown()
    }
    
//    func testOpenAIClient() async throws {
//        let openAITests = OpenAIClientTests()
//        openAITests.setUp()
//        try await openAITests.testSendMessage()
//        openAITests.tearDown()
//    }
//    
//    func testAzureOpenAIClient() async throws {
//        let azureOpenAITests = AzureOpenAIClientTests()
//        azureOpenAITests.setUp()
//        try await azureOpenAITests.testSendMessage()
//        azureOpenAITests.tearDown()
//    }
//    
//    func testOllamaClient() async throws {
//        let ollamaTests = OllamaClientTests()
//        ollamaTests.setUp()
//        try await ollamaTests.testSendMessage()
//        ollamaTests.tearDown()
//    }
//    
//    func testDeepSeekClient() async throws {
//        let deepSeekTests = DeepSeekClientTests()
//        deepSeekTests.setUp()
//        try await deepSeekTests.testSendMessage()
//        deepSeekTests.tearDown()
//    }
//    
//    func testChatGLMClient() async throws {
//        let chatGLMTests = ChatGLMClientTests()
//        chatGLMTests.setUp()
//        try await chatGLMTests.testSendMessage()
//        chatGLMTests.tearDown()
//    }
}
