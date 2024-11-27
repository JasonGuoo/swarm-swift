import Foundation

public class OllamaClient: OpenAIClient {
    public override init(apiKey: String = "ollama", baseURL: String = "http://localhost:11434/v1", modelName: String? = "llama3") {
        super.init(apiKey: apiKey, baseURL: baseURL, modelName: modelName)
    }
    
    override func createChatCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        // If model is not set in the request but we have a default model name, use it
        if request.json["model"].string == nil && modelName != nil {
            request.withModel(model: modelName!)
        }
        super.createChatCompletion(request: request, completion: completion)
    }
    
    override func createCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        // If model is not set in the request but we have a default model name, use it
        if request.json["model"].string == nil && modelName != nil {
            request.withModel(model: modelName!)
        }
        super.createCompletion(request: request, completion: completion)
    }
}
