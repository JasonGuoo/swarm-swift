import Foundation

public class DeepSeekClient: LLMClient {
    override init(apiKey: String, baseURL: String) {
        super.init(apiKey: apiKey, baseURL: baseURL)
    }

    override func createChatCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        let parameters: [String: Any] = [
            "model": "deepseek-chat",
            "messages": request.messages.map { ["role": $0.role, "content": $0.content] }
        ]

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
                completion(.failure(LLMError.requestFailed))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    let response = LLMResponse(id: "", object: "", created: 0, model: "", choices: [LLMResponse.Choice(index: 0, message: LLMMessage(role: "", content: content), finishReason: nil)], usage: nil, systemFingerprint: nil, error: nil)
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
        guard let url = URL(string: "\(baseURL)/completions") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        let parameters: [String: Any] = [
            "model": request.model,
            "prompt": request.messages.last?.content ?? "",
            "max_tokens": request.maxTokens ?? 100,
            "temperature": request.temperature ?? 0.7
        ]

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
                // Set the object type to "completion"
                llmResponse.object = "completion"
                completion(.success(llmResponse))
            case .failure(let error):
                DebugUtils.printDebug("Decoding Error: \(error.localizedDescription)")
                completion(.failure(LLMError.decodingFailed))
            }
        }

        task.resume()
    }

    override func createEmbedding(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Embedding creation is not supported for DeepSeek API in this implementation")))
    }

    override func createImage(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Image creation is not supported for DeepSeek API in this implementation")))
    }

    override func createTranscription(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Transcription is not supported for DeepSeek API in this implementation")))
    }

    override func createTranslation(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Translation is not supported for DeepSeek API in this implementation")))
    }
}
