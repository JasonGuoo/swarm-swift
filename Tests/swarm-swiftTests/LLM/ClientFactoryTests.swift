import XCTest
@testable import swarm_swift

final class ClientFactoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear environment variables before each test
        unsetAllEnvironmentVariables()
    }
    
    func testGetDefaultClient() {
        // Test when no configuration is available
        XCTAssertNil(ClientFactory.getDefaultClient())
        
        // Test with OpenAI configuration
        setEnvironmentVariables(for: "OpenAI")
        XCTAssertTrue(ClientFactory.getDefaultClient() is OpenAIClient)
        
        // Test with AzureOpenAI configuration
        setEnvironmentVariables(for: "AzureOpenAI")
        XCTAssertTrue(ClientFactory.getDefaultClient() is AzureOpenAIClient)
    }
    
    func testGetLLMClient() {
        // Test with explicit OpenAI configuration
        let openAIConfig = createConfig(for: "OpenAI")
        XCTAssertTrue(ClientFactory.getLLMClient(apiType: "OpenAI", config: openAIConfig) is OpenAIClient)
        
        // Test with explicit AzureOpenAI configuration
        let azureConfig = createConfig(for: "AzureOpenAI")
        XCTAssertTrue(ClientFactory.getLLMClient(apiType: "AzureOpenAI", config: azureConfig) is AzureOpenAIClient)
        
        // Test fallback to environment variables
        setEnvironmentVariables(for: "Ollama")
        XCTAssertTrue(ClientFactory.getLLMClient(apiType: "Ollama") is OllamaClient)
    }
    
    func testGetFromEnvironmentVariables() {
        setEnvironmentVariables(for: "DeepSeek")
        XCTAssertTrue(ClientFactory.getFromEnvironmentVariables(apiType: "DeepSeek") is DeepSeekClient)
        
        setEnvironmentVariables(for: "ChatGLM")
        XCTAssertTrue(ClientFactory.getFromEnvironmentVariables(apiType: "ChatGLM") is ChatGLMClient)
    }
    
    func testGetFromConfig() {
        let openAIConfig = createConfig(for: "OpenAI")
        XCTAssertTrue(ClientFactory.getFromConfig(apiType: "OpenAI", config: openAIConfig) is OpenAIClient)
        
        let azureConfig = createConfig(for: "AzureOpenAI")
        XCTAssertTrue(ClientFactory.getFromConfig(apiType: "AzureOpenAI", config: azureConfig) is AzureOpenAIClient)
    }
    
    // Helper methods
    
    private func setEnvironmentVariables(for apiType: String) {
        switch apiType {
        case "OpenAI":
            setenv("OpenAI_API_KEY", "test_key", 1)
            setenv("OpenAI_API_BASE_URL", "https://api.openai.com", 1)
        case "AzureOpenAI":
            setenv("AzureOpenAI_API_KEY", "test_key", 1)
            setenv("AzureOpenAI_API_BASE_URL", "https://your-resource-name.openai.azure.com", 1)
            setenv("AzureOpenAI_API_VERSION", "2023-05-15", 1)
            setenv("AzureOpenAI_DEPLOYMENT_ID", "deployment-id", 1)
        case "Ollama":
            setenv("Ollama_API_KEY", "test_key", 1)
            setenv("Ollama_API_BASE_URL", "http://localhost:11434", 1)
        case "DeepSeek":
            setenv("DeepSeek_API_KEY", "test_key", 1)
            setenv("DeepSeek_API_BASE_URL", "https://api.deepseek.com", 1)
        case "ChatGLM":
            setenv("ChatGLM_API_KEY", "test_key", 1)
            setenv("ChatGLM_API_BASE_URL", "https://api.chatglm.com", 1)
        default:
            break
        }
    }
    
    private func unsetAllEnvironmentVariables() {
        unsetenv("OpenAI_API_KEY")
        unsetenv("OpenAI_API_BASE_URL")
        unsetenv("AzureOpenAI_API_KEY")
        unsetenv("AzureOpenAI_API_BASE_URL")
        unsetenv("AzureOpenAI_API_VERSION")
        unsetenv("AzureOpenAI_DEPLOYMENT_ID")
        unsetenv("Ollama_API_KEY")
        unsetenv("Ollama_API_BASE_URL")
        unsetenv("DeepSeek_API_KEY")
        unsetenv("DeepSeek_API_BASE_URL")
        unsetenv("ChatGLM_API_KEY")
        unsetenv("ChatGLM_API_BASE_URL")
    }
    
    private func createConfig(for apiType: String) -> Config {
        let config = Config()
        switch apiType {
        case "OpenAI":
            config.setValue(forKey: "OpenAI_API_KEY", value: "test_key")
            config.setValue(forKey: "OpenAI_API_BASE_URL", value: "https://api.openai.com")
        case "AzureOpenAI":
            config.setValue(forKey: "AzureOpenAI_API_KEY", value: "test_key")
            config.setValue(forKey: "AzureOpenAI_API_BASE_URL", value: "https://your-resource-name.openai.azure.com")
            config.setValue(forKey: "AzureOpenAI_API_VERSION", value: "2023-05-15")
            config.setValue(forKey: "AzureOpenAI_DEPLOYMENT_ID", value: "deployment-id")
        default:
            break
        }
        return config
    }
}
