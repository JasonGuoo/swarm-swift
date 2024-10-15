import Foundation

public class AzureOpenAIClient: OpenAIClient {
    let apiVersion: String
    let deploymentId: String

    init(apiKey: String, baseURL: String, apiVersion: String, deploymentId: String) {
        self.apiVersion = apiVersion
        self.deploymentId = deploymentId
        super.init(apiKey: apiKey, baseURL: baseURL)
    }

    /// Creates a chat completion using the Azure OpenAI API.
    /// - Parameters:
    ///   - request: The LLMRequest containing the chat messages and parameters.
    ///   - completion: A closure to be called with the result of the API call.
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
            if key.lowercased() == "api-key" {
                let maskedValue = String(value.prefix(4)) + String(repeating: "*", count: max(0, value.count - 4))
                print("  \(key): \(maskedValue)")
            } else {
                print("  \(key): \(value)")
            }
        }
        #endif

        do {
            var modifiedRequest = request
            applyDefaultValues(&modifiedRequest)
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(modifiedRequest)
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

    /// Creates a text completion using the Azure OpenAI API.
    /// - Parameters:
    ///   - request: The LLMRequest containing the prompt and parameters.
    ///   - completion: A closure to be called with the result of the API call.
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
            if key.lowercased() == "api-key" {
                let maskedValue = String(value.prefix(4)) + String(repeating: "*", count: max(0, value.count - 4))
                print("  \(key): \(maskedValue)")
            } else {
                print("  \(key): \(value)")
            }
        }
        #endif

        do {
            var modifiedRequest = request
            applyDefaultValues(&modifiedRequest)
            
            let completionRequest = CompletionRequest(from: modifiedRequest)
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(completionRequest)
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

    /// Creates an embedding using the Azure OpenAI API.
    /// - Parameters:
    ///   - request: The LLMRequest containing the text to be embedded.
    ///   - completion: A closure to be called with the result of the API call.
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

    /// Applies default values to an LLMRequest if certain parameters are not set.
    /// - Parameter request: The LLMRequest to be modified.
    private func applyDefaultValues(_ request: inout LLMRequest) {
        request.maxTokens = request.maxTokens ?? 4096
        request.temperature = request.temperature ?? 0.7
        request.topP = request.topP ?? 1.0
        request.frequencyPenalty = request.frequencyPenalty ?? 0.0
        request.presencePenalty = request.presencePenalty ?? 0.0
        request.stop = request.stop ?? []
    }

    /// Represents a request for text completion to be sent to the Azure OpenAI API.
    /// This struct is used to format the request body according to the API's requirements.
    private struct CompletionRequest: Codable {
        let prompt: String
        let maxTokens: Int
        let temperature: Double
        let topP: Double
        let frequencyPenalty: Double
        let presencePenalty: Double
        let stop: [String]

        /// Initializes a CompletionRequest from an LLMRequest, applying default values where necessary.
        /// - Parameter request: The LLMRequest to convert into a CompletionRequest.
        init(from request: LLMRequest) {
            self.prompt = request.messages.last?.content ?? ""
            self.maxTokens = request.maxTokens ?? 100
            self.temperature = request.temperature ?? 0.7
            self.topP = request.topP ?? 1.0
            self.frequencyPenalty = request.frequencyPenalty ?? 0.0
            self.presencePenalty = request.presencePenalty ?? 0.0
            self.stop = request.stop ?? []
        }
    }
}
