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
    
    override func createChatCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        let endpoint = "\(baseURL)"
        performRequest(request: request, endpoint: endpoint, completion: completion)
    }
    
    override func createCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        
        createChatCompletion(request: request, completion: completion)
    }
    
    override func createEmbedding(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "ChatGLMClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Embedding creation is not supported for ChatGLM API in this implementation"])))
    }

    override func createImage(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "ChatGLMClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image creation is not supported for ChatGLM API in this implementation"])))
    }

    override func createTranscription(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "ChatGLMClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Transcription is not supported for ChatGLM API in this implementation"])))
    }

    override func createTranslation(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "ChatGLMClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Translation is not supported for ChatGLM API in this implementation"])))
    }

    internal func performRequest(request: Request, endpoint: String, completion: @escaping (Result<Response, Error>) -> Void) {
        // Ensure the endpoint URL is valid
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "ChatGLMClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
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
            request.withModel(model:ModelType.glm4Flash.rawValue) // Use the default model or allow it to be specified
            let jsonData = try request.rawData()
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
                completion(.failure(NSError(domain: "ChatGLMClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            DebugUtils.printDebugJSON(data)

            // Parse the JSON response
            do {
                var response = try Response(data: data)
                response.json["object"] = "chat.completion"
                completion(.success(response))
            } catch {
                DebugUtils.printDebug("Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        // Start the network request
        task.resume()
    }
}

// Note: The ChatGLMResponse struct can be removed if it's no longer needed,
// as we're now using the generic Response class.
