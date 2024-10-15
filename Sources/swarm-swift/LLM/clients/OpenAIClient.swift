import Foundation
import AVFoundation

public class OpenAIClient: LLMClient {
    override init(apiKey: String, baseURL: String) {
        super.init(apiKey: apiKey, baseURL: baseURL)
    }

    override func createChatCompletion(request: LLMRequest, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(LLMError.invalidURL))
            return
        }
        print("baseURL: \(baseURL)")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

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
        guard let url = URL(string: "\(baseURL)/completions") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let completionRequest = [
            "model": request.model,
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
        guard let url = URL(string: "\(baseURL)/embeddings") else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let embeddingRequest: [String: Any] = [
            "model": request.model,
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
                
                // 将EmbeddingResponse转换为LLMResponse
                let llmResponse = LLMResponse(
                    id: embeddingResponse.id,
                    object: embeddingResponse.object,
                    created: embeddingResponse.created,
                    model: embeddingResponse.model,
                    choices: [], // Embedding不使用choices
                    usage: LLMResponse.Usage(
                        promptTokens: embeddingResponse.usage.promptTokens,
                        completionTokens: 0, // Embedding不使用completionTokens
                        totalTokens: embeddingResponse.usage.totalTokens
                    ),
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
}

// 用于解析Embedding响应的结构
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

// 用于解析转录和翻译响应的结构
struct TranscriptionResponse: Codable {
    let text: String
}

struct TranslationResponse: Codable {
    let text: String
}