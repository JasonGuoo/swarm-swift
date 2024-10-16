import Foundation
import AVFoundation

public class OpenAIClient: LLMClient {
    override public init(apiKey: String, baseURL: String) {
        super.init(apiKey: apiKey, baseURL: baseURL)
    }

    override func createChatCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        let endpoint = "\(baseURL)/chat/completions"
        performRequest(request: request, endpoint: endpoint, completion: completion)
    }

    override func createCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        let endpoint = "\(baseURL)/completions"
        performRequest(request: request, endpoint: endpoint, completion: completion)
    }

    override func createEmbedding(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        let endpoint = "\(baseURL)/embeddings"
        performRequest(request: request, endpoint: endpoint, completion: completion)
    }

    override func createImage(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Image creation is not supported for OpenAI API in this implementation")))
    }

    override func createSpeech(request: LLMRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Speech creation is not supported for OpenAI API in this implementation")))
    }

    override func createTranscription(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Transcription is not implemented for OpenAI API in this client")))
    }

    override func createTranslation(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        completion(.failure(LLMError.unsupportedOperation("Translation is not implemented for OpenAI API in this client")))
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
            let jsonData = try encoder.encode(request)
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
                // Set the object type to "translation" (Note: This might need to be adjusted based on the actual response)
                llmResponse.object = "translation" 
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

// Structure for parsing Embedding response
struct EmbeddingResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let data: [EmbeddingData]
    let usage: EmbeddingUsage

    struct EmbeddingData: Codable {
        let embedding: [Double]
        let index: Int
        let object: String
    }

    struct EmbeddingUsage: Codable {
        let promptTokens: Int
        let totalTokens: Int
    }
}

// Structures for parsing transcription and translation responses
struct TranscriptionResponse: Codable {
    let text: String
}

struct TranslationResponse: Codable {
    let text: String
}
