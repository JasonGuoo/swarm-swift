import Foundation

public class ChatGLMClient: LLMClient {
    enum ModelType: String {
        case glm40520 = "glm-4-0520" // High-intelligence model: Suitable for handling highly complex and diverse tasks
        case glm4Air = "glm-4-air" // Best value: Most balanced model between inference capability and price
        case glm4AirX = "glm-4-airx" // Ultra-fast inference: Super-fast inference speed with powerful inference effects, supports 8k context
        case glm4Flash = "glm-4-flash" // Free to use: ZhipuAI's first free API, zero-cost access to large models
    }
    
    override public init(apiKey: String, baseURL: String) {
        super.init(apiKey: apiKey, baseURL: baseURL)
    }
    
    override func createChatCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        let endpoint = "\(baseURL)"
        performRequest(request: request, endpoint: endpoint, completion: completion)
    }
    
    override func createCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        let chatRequest = LLMRequest(
            model: request.model,
            messages: [LLMMessage(role: "user", content: request.messages.last?.content ?? "")],
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

    internal func performRequest(request: LLMRequest, endpoint: String, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        // Ensure the endpoint URL is valid
        guard let url = URL(string: endpoint) else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        DebugUtils.printDebug("Request URL: \(url.absoluteString)")

        // Set up the URLRequest with necessary headers
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        DebugUtils.printDebugHeaders(urlRequest.allHTTPHeaderFields ?? [:])

        // Encode the request body
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            var modifiedRequest = request
            modifiedRequest.model = ModelType.glm4Flash.rawValue // Use the default model or allow it to be specified
            let jsonData = try encoder.encode(modifiedRequest)
            urlRequest.httpBody = jsonData
            DebugUtils.printDebugJSON(jsonData)
        } catch {
            completion(.failure(error))
            return
        }

        // Create and start the network request
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            // Handle network errors
            if let error = error {
                DebugUtils.printDebug("Network Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            // Log HTTP response details
            if let httpResponse = response as? HTTPURLResponse {
                DebugUtils.printDebug("HTTP Status Code: \(httpResponse.statusCode)")
                DebugUtils.printDebugHeaders(httpResponse.allHeaderFields as? [String: String] ?? [:])
            }

            // Ensure we received data
            guard let data = data else {
                DebugUtils.printDebug("No data received")
                completion(.failure(LLMError.requestFailed))
                return
            }

            DebugUtils.printDebugJSON(data)

            // Convert data to JSON string
            guard let jsonString = String(data: data, encoding: .utf8) else {
                DebugUtils.printDebug("Failed to convert data to string")
                completion(.failure(LLMError.decodingFailed))
                return
            }

            // Parse the JSON response
            let result = LLMResponse.fromJSON(jsonString)
            switch result {
            case .success(var llmResponse):
                llmResponse.object = "chat.completion"
                completion(.success(llmResponse))
            case .failure(let error):
                DebugUtils.printDebug("Decoding Error: \(error.localizedDescription)")
                completion(.failure(LLMError.decodingFailed))
            }
        }

        // Start the network request
        task.resume()
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
