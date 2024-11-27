import Foundation
import AVFoundation

public class OpenAIClient: LLMClient {
    override public init(apiKey: String, baseURL: String, modelName: String? = nil) {
        super.init(apiKey: apiKey, baseURL: baseURL, modelName: modelName)
    }

    override func createChatCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        let endpoint = "\(baseURL)/chat/completions"
        // If model is not set in the request but we have a default model name, use it
        if request.json["model"].string == nil && modelName != nil {
            request.withModel(model: modelName!)
        }
        performRequest(request: request, endpoint: endpoint, completion: completion)
    }

    override func createCompletion(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        let endpoint = "\(baseURL)/completions"
        // If model is not set in the request but we have a default model name, use it
        if request.json["model"].string == nil && modelName != nil {
            request.withModel(model: modelName!)
        }
        performRequest(request: request, endpoint: endpoint, completion: completion)
    }

    override func createEmbedding(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        let endpoint = "\(baseURL)/embeddings"
        // If model is not set in the request but we have a default model name, use it
        if request.json["model"].string == nil && modelName != nil {
            request.withModel(model: modelName!)
        }
        performRequest(request: request, endpoint: endpoint, completion: completion)
    }

    override func createImage(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "OpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image creation is not supported for OpenAI API in this implementation"])))
    }

    override func createSpeech(request: Request, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.failure(NSError(domain: "OpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech creation is not supported for OpenAI API in this implementation"])))
    }

    override func createTranscription(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "OpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Transcription is not implemented for OpenAI API in this client"])))
    }

    override func createTranslation(request: Request, completion: @escaping (Result<Response, Error>) -> Void) {
        completion(.failure(NSError(domain: "OpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Translation is not implemented for OpenAI API in this client"])))
    }

    internal func performRequest(request: Request, endpoint: String, completion: @escaping (Result<Response, Error>) -> Void) {
        // Ensure the endpoint URL is valid
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "OpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
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
                completion(.failure(NSError(domain: "OpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            DebugUtils.printDebugJSON(data)

            // Parse the JSON response
            do {
                let response = try Response(data: data)
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
