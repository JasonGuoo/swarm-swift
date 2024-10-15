import Foundation

public class AzureOpenAIClient: LLMClient {
    let apiVersion: String
    let deploymentId: String

    init(apiKey: String, baseURL: String, apiVersion: String, deploymentId: String) {
        self.apiVersion = apiVersion
        self.deploymentId = deploymentId
        super.init(apiKey: apiKey, baseURL: baseURL)
    }

    override func createChatCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/openai/deployments/\(deploymentId)/chat/completions?api-version=\(apiVersion)") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(request)
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
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let apiResponse = try decoder.decode(LLMResponse.self, from: data)
                completion(.success(apiResponse))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    override func createCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/openai/deployments/\(deploymentId)/completions?api-version=\(apiVersion)") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")

        let completionRequest = [
            "prompt": request.messages.last?.content ?? "",
            "max_tokens": request.maxTokens ?? 100,
            "temperature": request.temperature ?? 0.7
        ] as [String : Any]

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: completionRequest)
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
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let apiResponse = try decoder.decode(LLMResponse.self, from: data)
                completion(.success(apiResponse))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    override func createEmbedding(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/openai/deployments/\(deploymentId)/embeddings?api-version=\(apiVersion)") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")

        let embeddingRequest: [String: Any] = [
            "input": request.messages.last?.content ?? "",
            "user": request.user ?? ""
        ]

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: embeddingRequest)
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
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let embeddingResponse = try decoder.decode(EmbeddingResponse.self, from: data)
                
                let aiResponse = LLMResponse(
                    id: embeddingResponse.id,
                    object: embeddingResponse.object,
                    created: embeddingResponse.created,
                    model: embeddingResponse.model,
                    choices: [],
                    usage: LLMResponse.Usage(
                        promptTokens: embeddingResponse.usage.promptTokens,
                        completionTokens: 0,
                        totalTokens: embeddingResponse.usage.totalTokens
                    ),
                    systemFingerprint: nil,
                    error: nil
                )
                
                completion(.success(aiResponse))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    // Other methods (createImage, createSpeech, createTranscription, createTranslation) 
    // can remain unchanged or be adjusted based on Azure OpenAI's support
}
