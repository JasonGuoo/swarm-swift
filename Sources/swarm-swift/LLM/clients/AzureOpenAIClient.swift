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

        #if DEBUG
        print("Request URL: \(url.absoluteString)")
        #endif

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")

        #if DEBUG
        print("Request Headers:")
        urlRequest.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        #endif

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(request)
            urlRequest.httpBody = jsonData
            #if DEBUG
            print("Request Body:")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
            #endif
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                #if DEBUG
                print("Network Error: \(error.localizedDescription)")
                #endif
                completion(.failure(error))
                return
            }

            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                print("Response Headers:")
                httpResponse.allHeaderFields.forEach { key, value in
                    print("  \(key): \(value)")
                }
            }
            #endif

            guard let data = data else {
                #if DEBUG
                print("No data received")
                #endif
                completion(.failure(LLMError.requestFailed))
                return
            }

            #if DEBUG
            print("Raw Response Data:")
            if let rawResponse = String(data: data, encoding: .utf8) {
                print(rawResponse)
            }
            #endif

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let apiResponse = try decoder.decode(LLMResponse.self, from: data)
                completion(.success(apiResponse))
            } catch {
                #if DEBUG
                print("Decoding Error: \(error.localizedDescription)")
                #endif
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
        
        #if DEBUG
        print("Request URL: \(url.absoluteString)")
        #endif

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        #if DEBUG
        print("Request Headers:")
        urlRequest.allHTTPHeaderFields?.forEach { key, value in
            print("  \(key): \(value)")
        }
        #endif

        let completionRequest = [
            "prompt": request.messages.last?.content ?? "",
            "max_tokens": request.maxTokens ?? 100,
            "temperature": request.temperature ?? 0.7
        ] as [String : Any]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: completionRequest, options: .prettyPrinted)
            urlRequest.httpBody = jsonData
            #if DEBUG
            print("Request Body:")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
            #endif
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                #if DEBUG
                print("Network Error: \(error.localizedDescription)")
                #endif
                completion(.failure(error))
                return
            }

            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                print("Response Headers:")
                httpResponse.allHeaderFields.forEach { key, value in
                    print("  \(key): \(value)")
                }
            }
            #endif

            guard let data = data else {
                #if DEBUG
                print("No data received")
                #endif
                completion(.failure(LLMError.requestFailed))
                return
            }

            #if DEBUG
            print("Raw Response Data:")
            if let rawResponse = String(data: data, encoding: .utf8) {
                print(rawResponse)
            }
            #endif

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let apiResponse = try decoder.decode(LLMResponse.self, from: data)
                completion(.success(apiResponse))
            } catch {
                #if DEBUG
                print("Decoding Error: \(error.localizedDescription)")
                #endif
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
