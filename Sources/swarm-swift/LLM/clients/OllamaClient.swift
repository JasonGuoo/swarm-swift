import Foundation

public class OllamaClient: LLMClient {
    override init(apiKey: String, baseURL: String) {
        super.init(apiKey: apiKey, baseURL: baseURL)
    }

    override func createChatCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        let model = "llama3"
        let parameters: [String: Any] = [
            "model": model,
            "prompt": "\(request.messages.first?.content ?? "")\n现在请用中文回答用户的问题(答案只需要json格式的部分，并确保是合法的json格式)：\n \(request.messages.last?.content ?? "")",
            "stream": false
        ]

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
                completion(.failure(LLMError.requestFailed))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let generatedText = json["response"] as? String {
                    let response = LLMResponse(id: "", object: "", created: 0, model: "", choices: [LLMResponse.Choice(index: 0, message: LLMResponse.Message(role: "", content: generatedText, toolCalls: nil), finishReason: nil)], usage: nil, systemFingerprint: nil, error: nil)
                    completion(.success(response))
                } else {
                    completion(.failure(LLMError.decodingFailed))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    override func createCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        let parameters: [String: Any] = [
            "model": request.model,
            "prompt": request.messages.last?.content ?? "",
            "stream": false,
            "options": [
                "num_predict": request.maxTokens ?? 100,
                "temperature": request.temperature ?? 0.7
            ]
        ]

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
                completion(.failure(LLMError.requestFailed))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let generatedText = json["response"] as? String {
                    let response = LLMResponse(id: "", object: "", created: 0, model: request.model, choices: [LLMResponse.Choice(index: 0, message: LLMResponse.Message(role: "", content: generatedText, toolCalls: nil), finishReason: nil)], usage: nil, systemFingerprint: nil, error: nil)
                    completion(.success(response))
                } else {
                    completion(.failure(LLMError.decodingFailed))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    override func createEmbedding(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Embedding creation is not supported for Ollama API in this implementation")))
    }

    override func createImage(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Image creation is not supported for Ollama API in this implementation")))
    }

    override func createTranscription(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Transcription is not supported for Ollama API in this implementation")))
    }

    override func createTranslation(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Translation is not supported for Ollama API in this implementation")))
    }
}
