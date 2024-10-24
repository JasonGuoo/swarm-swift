import Foundation

public class OllamaClient: LLMClient {
    override public init(apiKey: String, baseURL: String) {
        super.init(apiKey: apiKey, baseURL: baseURL)
    }

    override func createChatCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            completion(.failure(NSError(domain: "OllamaClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let model = "llama3"
        let parameters: [String: Any] = [
            "model": model,
            "prompt": "\(request.json["messages"].arrayValue.first?["content"].stringValue ?? "")\n现在请用中文回答用户的问题(答案只需要json格式的部分，并确保是合法的json格式)：\n \(request.json["messages"].arrayValue.last?["content"].stringValue ?? "")",
            "stream": false
        ]

        performRequest(url: url, parameters: parameters, completion: completion)
    }

    override func createCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            completion(.failure(NSError(domain: "OllamaClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let parameters: [String: Any] = [
            "model": request.json["model"].stringValue,
            "prompt": request.json["messages"].arrayValue.last?["content"].stringValue ?? "",
            "stream": false,
            "options": [
                "num_predict": request.json["max_tokens"].intValue,
                "temperature": request.json["temperature"].floatValue
            ]
        ]

        performRequest(url: url, parameters: parameters, completion: completion)
    }

    override func createEmbedding(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "OllamaClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Embedding creation is not supported for Ollama API in this implementation"])))
    }

    override func createImage(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "OllamaClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image creation is not supported for Ollama API in this implementation"])))
    }

    override func createTranscription(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "OllamaClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Transcription is not supported for Ollama API in this implementation"])))
    }

    override func createTranslation(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "OllamaClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Translation is not supported for Ollama API in this implementation"])))
    }

    private func performRequest(url: URL, parameters: [String: Any], completion: @escaping (Result<Response, Error>) -> Void) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
                completion(.failure(NSError(domain: "OllamaClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let generatedText = json["response"] as? String {
                    let responseJSON: [String: Any] = [
                        "choices": [
                            [
                                "message": [
                                    "role": "assistant",
                                    "content": generatedText
                                ]
                            ]
                        ]
                    ]
                    let responseData = try JSONSerialization.data(withJSONObject: responseJSON)
                    let response = try Response(data: responseData)
                    completion(.success(response))
                } else {
                    completion(.failure(NSError(domain: "OllamaClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}
