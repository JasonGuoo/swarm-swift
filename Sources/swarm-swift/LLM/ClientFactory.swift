import Foundation

public class ClientFactory {
    
    /// Creates an LLM client based on the specified API type and configuration.
    /// - Parameters:
    ///   - apiType: The type of LLM API to use. Defaults to "OpenAI".
    ///   - config: A Config instance. If not provided, it returns nil.
    /// - Returns: An LLMClient instance if successful, nil otherwise.
    public static func getLLMClient(apiType: String = "OpenAI", config: Config? = nil) -> LLMClient? {
        guard let config = config else {
            return nil
        }
        return createClient(apiType: apiType, config: config)
    }


    private static func createClient(apiType: String, config: Config) -> LLMClient? {
        switch apiType {
        case "OpenAI":
            return createOpenAIClient(config: config)
        case "AzureOpenAI":
            return createAzureOpenAIClient(config: config)
        case "Ollama":
            return createOllamaClient(config: config)
        case "DeepSeek":
            return createDeepSeekClient(config: config)
        case "ChatGLMAPI", "ChatGLM":
            return createChatGLMClient(config: config)
        default:
            return createOpenAIClient(config: config)
        }
    }
    
    private static func createOpenAIClient(config: Config) -> OpenAIClient? {
        guard let apiKey = config.value(forKey: "OpenAI_API_KEY"),
              let baseURL = config.value(forKey: "OpenAI_API_BASE_URL") else { return nil }
        let modelName = config.value(forKey: "OpenAI_MODEL_NAME")
        return OpenAIClient(apiKey: apiKey, baseURL: baseURL, modelName: modelName)
    }
    
    private static func createAzureOpenAIClient(config: Config) -> AzureOpenAIClient? {
        guard let apiKey = config.value(forKey: "AzureOpenAI_API_KEY"),
              let endpoint = config.value(forKey: "AzureOpenAI_API_BASE_URL"),
              let apiVersion = config.value(forKey: "AzureOpenAI_API_VERSION"),
              let deploymentId = config.value(forKey: "AzureOpenAI_DEPLOYMENT_ID") else { return nil }
        let modelName = config.value(forKey: "AzureOpenAI_MODEL_NAME")
        return AzureOpenAIClient(apiKey: apiKey, 
                               endpoint: endpoint, 
                               apiVersion: apiVersion, 
                               deploymentId: deploymentId, 
                               modelName: modelName)
    }
    
    private static func createOllamaClient(config: Config) -> OllamaClient? {
        guard let apiKey = config.value(forKey: "Ollama_API_KEY"),
              let baseURL = config.value(forKey: "Ollama_API_BASE_URL") else { return nil }
        // Use llama3 as default model if not specified in config
        let modelName = config.value(forKey: "Ollama_MODEL_NAME") ?? "llama3"
        return OllamaClient(apiKey: apiKey, baseURL: baseURL, modelName: modelName)
    }
    
    private static func createDeepSeekClient(config: Config) -> DeepSeekClient? {
        guard let apiKey = config.value(forKey: "DeepSeek_API_KEY"),
              let baseURL = config.value(forKey: "DeepSeek_API_BASE_URL") else { return nil }
        return DeepSeekClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    private static func createChatGLMClient(config: Config) -> ChatGLMClient? {
        guard let apiKey = config.value(forKey: "ChatGLM_API_KEY"),
              let baseURL = config.value(forKey: "ChatGLM_API_BASE_URL") else { return nil }
        // Use glm-4-flash as default model if not specified in config
        let modelName = config.value(forKey: "ChatGLM_MODEL_NAME") ?? "glm-4-flash"
        return ChatGLMClient(apiKey: apiKey, baseURL: baseURL, modelName: modelName)
    }
}
