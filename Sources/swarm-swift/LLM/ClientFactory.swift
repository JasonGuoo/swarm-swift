import Foundation

public func getLLMClient(apiType: String) -> LLMClient? {
    let config = Config.shared

    switch apiType {
    case "OpenAI":
        if let apiKey = config.value(forKey: "OpenAI_API_KEY"),
           let baseURL = config.value(forKey: "OpenAI_API_BASE_URL") {
            return OpenAIClient(apiKey: apiKey, baseURL: baseURL)
        }
    case "AzureOpenAI":
        if let apiKey = config.value(forKey: "AzureOpenAI_API_KEY"),
           let baseURL = config.value(forKey: "AzureOpenAI_API_BASE_URL"),
           let apiVersion = config.value(forKey: "AzureOpenAI_API_VERSION"),
           let deploymentId = config.value(forKey: "AzureOpenAI_DEPLOYMENT_ID") {
            return AzureOpenAIClient(apiKey: apiKey, baseURL: baseURL, apiVersion: apiVersion, deploymentId: deploymentId)
        }
    case "Ollama":
        if let apiKey = config.value(forKey: "Ollama_API_KEY"),
           let baseURL = config.value(forKey: "Ollama_API_BASE_URL") {
            return OllamaClient(apiKey: apiKey, baseURL: baseURL)
        }
    case "DeepSeek":
        if let apiKey = config.value(forKey: "DeepSeek_API_KEY"),
           let baseURL = config.value(forKey: "DeepSeek_API_BASE_URL") {
            return DeepSeekClient(apiKey: apiKey, baseURL: baseURL)
        }
    case "ChatGLMAPI", "ChatGLM":
        if let apiKey = config.value(forKey: "ChatGLM_API_KEY"),
           let baseURL = config.value(forKey: "ChatGLM_API_BASE_URL") {
            return ChatGLMClient(apiKey: apiKey, baseURL: baseURL)
        }
    default:
        return nil
    }

    return nil
}

