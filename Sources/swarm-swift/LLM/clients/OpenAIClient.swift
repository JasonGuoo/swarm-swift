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
        guard let url = URL(string: "\(baseURL)/audio/speech") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let speechRequest: [String: Any] = [
            "model": request.model,
            "input": request.messages.last?.content ?? "",
            "voice": request.voice ?? "alloy",
            "response_format": request.responseFormat ?? "mp3",
            "speed": request.speed ?? 1.0
        ]

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: speechRequest)
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

            completion(.success(data))
        }

        task.resume()
    }

    override func createTranscription(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/audio/transcriptions") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body = Data()

        // Add file data
        if let fileData = request.fileData, let fileName = request.fileName {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // Add other parameters
        let parameters: [String: Any] = [
            "model": request.model,
            "language": request.language ?? "",
            "prompt": request.messages.last?.content ?? "",
            "response_format": request.responseFormat ?? "json",
            "temperature": request.temperature ?? 0
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

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
                let transcriptionResponse = try decoder.decode(TranscriptionResponse.self, from: data)
                
                let llmResponse = LLMResponse(
                    id: "",
                    object: "transcription",
                    created: Int(Date().timeIntervalSince1970),
                    model: request.model,
                    choices: [LLMResponse.Choice(index: 0, message: LLMRequest.Message(role: "assistant", content: transcriptionResponse.text), finishReason: "stop")],
                    usage: nil,
                    systemFingerprint: nil,
                    error: nil
                )
                
                completion(.success(llmResponse))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    override func createTranslation(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/audio/translations") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var body = Data()

        // Add file data
        if let fileData = request.fileData, let fileName = request.fileName {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        // Add other parameters
        let parameters: [String: Any] = [
            "model": request.model,
            "prompt": request.messages.last?.content ?? "",
            "response_format": request.responseFormat ?? "json",
            "temperature": request.temperature ?? 0
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

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
                let translationResponse = try decoder.decode(TranslationResponse.self, from: data)
                
                let llmResponse = LLMResponse(
                    id: "",
                    object: "translation",
                    created: Int(Date().timeIntervalSince1970),
                    model: request.model,
                    choices: [LLMResponse.Choice(index: 0, message: LLMRequest.Message(role: "assistant", content: translationResponse.text), finishReason: "stop")],
                    usage: nil,
                    systemFingerprint: nil,
                    error: nil
                )
                
                completion(.success(llmResponse))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }

    internal func performRequest(request: LLMRequest, endpoint: String, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        DebugUtils.printDebug("Request URL: \(url.absoluteString)")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        DebugUtils.printDebugHeaders(urlRequest.allHTTPHeaderFields ?? [:])

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

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                DebugUtils.printDebug("Network Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                DebugUtils.printDebug("HTTP Status Code: \(httpResponse.statusCode)")
                DebugUtils.printDebugHeaders(httpResponse.allHeaderFields as? [String: String] ?? [:])
            }

            guard let data = data else {
                DebugUtils.printDebug("No data received")
                completion(.failure(LLMError.requestFailed))
                return
            }

            DebugUtils.printDebugJSON(data)

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let apiResponse = try decoder.decode(LLMResponse.self, from: data)
                completion(.success(apiResponse))
            } catch {
                DebugUtils.printDebug("Decoding Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

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