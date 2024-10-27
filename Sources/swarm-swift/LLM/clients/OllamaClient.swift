import Foundation

public class OllamaClient: OpenAIClient {
    public override init(apiKey: String = "ollama", baseURL: String = "http://localhost:11434/v1") {
        super.init(apiKey: apiKey, baseURL: baseURL)
    }
    
    // Override any methods if needed for Ollama-specific behavior
    // For now, we'll assume full compatibility with OpenAI API
}
