import Foundation

public class ChatGLMClient: LLMClient {
    enum ModelType: String {
        case glm40520 = "glm-4-0520" // High-intelligence model: Suitable for handling highly complex and diverse tasks
        case glm4Air = "glm-4-air" // Best value: Most balanced model between inference capability and price
        case glm4AirX = "glm-4-airx" // Ultra-fast inference: Super-fast inference speed with powerful inference effects, supports 8k context
        case glm4Flash = "glm-4-flash" // Free to use: ZhipuAI's first free API, zero-cost access to large models
    }
    
    override init(apiKey: String, baseURL: String) {
        super.init(apiKey: apiKey, baseURL: baseURL)
    }
    
    override func createChatCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        sendMessage(request: request, completion: completion)
    }
    
    func sendMessage(
        request: LLMRequest,
        modelType: ModelType = .glm4Flash, // use the free model as default
        completion: @escaping (Result<LLMResponse, Error>) -> Void
    ) {
        let model = modelType.rawValue
        var parameters: [String: Any] = [
            "model": model,
            "messages": request.messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": request.temperature ?? 0.7,
            "top_p": request.topP ?? 1,
            "max_tokens": request.maxTokens ?? 1500,
            "stream": request.stream ?? false
        ]
        
        if let n = request.n { parameters["n"] = n }
        if let stop = request.stop { parameters["stop"] = stop }
        if let presencePenalty = request.presencePenalty { parameters["presence_penalty"] = presencePenalty }
        if let frequencyPenalty = request.frequencyPenalty { parameters["frequency_penalty"] = frequencyPenalty }
        if let user = request.user { parameters["user"] = user }
        
        guard let url = URL(string: baseURL) else {
            completion(.failure(LLMError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(LLMError.requestFailed))
                return
            }
            
            self.handleResponse(data: data, completion: completion)
        }
        
        task.resume()
    }
    
    private func handleResponse(data: Data, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let apiResponse = try decoder.decode(ChatGLMResponse.self, from: data)
            
            let llmResponse = LLMResponse(
                id: apiResponse.id,
                object: apiResponse.object,
                created: apiResponse.created,
                model: apiResponse.model,
                choices: apiResponse.choices.map { choice in
                    LLMResponse.Choice(
                        index: choice.index,
                        message: LLMResponse.Message(
                            role: choice.message.role,
                            content: choice.message.content,
                            toolCalls: nil  // Add this line, set to nil if ChatGLM doesn't support tool calls
                        ),
                        finishReason: choice.finishReason
                    )
                },
                usage: LLMResponse.Usage(
                    promptTokens: apiResponse.usage.promptTokens,
                    completionTokens: apiResponse.usage.completionTokens,
                    totalTokens: apiResponse.usage.totalTokens
                ),
                systemFingerprint: nil,
                error: nil
            )
            
            completion(.success(llmResponse))
        } catch {
            completion(.failure(LLMError.decodingFailed))
        }
    }
    
    override func createCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        // ChatGLM API 可能不支持非对话式的完成，所以我们将其转换为对话式请求
        let chatRequest = LLMRequest(
            model: request.model,
            messages: [LLMRequest.Message(role: "user", content: request.messages.last?.content ?? "")],
            temperature: request.temperature,
            maxTokens: request.maxTokens
        )
        createChatCompletion(request: chatRequest, completion: completion)
    }
    
    override func createEmbedding(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Embedding creation is not supported for ChatGLM API in this implementation")))
    }

    override func createImage(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Image creation is not supported for ChatGLM API in this implementation")))
    }

    override func createTranscription(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Transcription is not supported for ChatGLM API in this implementation")))
    }

    override func createTranslation(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Translation is not supported for ChatGLM API in this implementation")))
    }
}

// ChatGLM API 响应结构
struct ChatGLMResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage

    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
    }

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }
}
