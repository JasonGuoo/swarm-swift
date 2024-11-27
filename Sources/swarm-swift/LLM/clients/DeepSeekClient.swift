import Foundation

public class DeepSeekClient: LLMClient {
    override public init(apiKey: String, baseURL: String, modelName: String? = "deepseek-chat") {
        super.init(apiKey: apiKey, baseURL: baseURL, modelName: modelName)
    }

    override func createChatCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(NSError(domain: "DeepSeekClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let parameters: [String: Any] = [
            "model": modelName ?? "deepseek-chat",
            "messages": request.json["messages"].arrayValue.map { ["role": $0["role"].stringValue, "content": $0["content"].stringValue] }
        ]

        performRequest(url: url, parameters: parameters, completion: completion)
    }

    override func createCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/completions") else {
            completion(.failure(NSError(domain: "DeepSeekClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let parameters: [String: Any] = [
            "model": modelName ?? "deepseek-chat",
            "prompt": request.json["messages"].arrayValue.last?["content"].stringValue ?? "",
            "max_tokens": request.json["max_tokens"].intValue,
            "temperature": request.json["temperature"].floatValue
        ]

        performRequest(url: url, parameters: parameters, completion: completion)
    }

    override func createEmbedding(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "DeepSeekClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Embedding creation is not supported for DeepSeek API in this implementation"])))
    }

    override func createImage(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "DeepSeekClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image creation is not supported for DeepSeek API in this implementation"])))
    }

    override func createTranscription(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "DeepSeekClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Transcription is not supported for DeepSeek API in this implementation"])))
    }

    override func createTranslation(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "DeepSeekClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Translation is not supported for DeepSeek API in this implementation"])))
    }

    private func performRequest(url: URL, parameters: [String: Any], completion: @escaping (Result<Response, Error>) -> Void) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
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
                completion(.failure(NSError(domain: "DeepSeekClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                var response = try Response(data: data)
                if url.absoluteString.contains("/chat/completions") {
                    response.json["object"] = "chat.completion"
                } else if url.absoluteString.contains("/completions") {
                    response.json["object"] = "completion"
                }
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}
