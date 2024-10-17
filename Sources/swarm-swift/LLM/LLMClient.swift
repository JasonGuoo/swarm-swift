//
//  LLMClient.swift
//  swarm-swift
//
//  Created by Jason Guo on 2024/10/10.
//

import Foundation

public class LLMClient {
    var apiKey: String
    var baseURL: String

    init(apiKey: String, baseURL: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    // Main method for creating chat completions
    func createChatCompletion(request: LLMRequest, completion: @escaping (Swift.Result<LLMResponse, Error>) -> Void) {
        fatalError("createChatCompletion method must be implemented in subclass")
    }

    // Optional: For creating text completions (if supported by the API)
    func createCompletion(request: LLMRequest, completion: @escaping (Swift.Result<LLMResponse, Error>) -> Void) {
        fatalError("createCompletion method must be implemented in subclass")
    }

    // Optional: For creating embeddings (if supported by the API)
    func createEmbedding(request: LLMRequest, completion: @escaping (Swift.Result<LLMResponse, Error>) -> Void) {
        fatalError("createEmbedding method must be implemented in subclass")
    }

    // Optional: For creating images (if supported by the API)
    func createImage(request: LLMRequest, completion: @escaping (Swift.Result<LLMResponse, Error>) -> Void) {
        fatalError("createImage method must be implemented in subclass")
    }

    // Optional: For audio transcription (if supported by the API)
    func createTranscription(request: LLMRequest, completion: @escaping (Swift.Result<LLMResponse, Error>) -> Void) {
        fatalError("createTranscription method must be implemented in subclass")
    }

    // Optional: For audio translation (if supported by the API)
    func createTranslation(request: LLMRequest, completion: @escaping (Swift.Result<LLMResponse, Error>) -> Void) {
        fatalError("createTranslation method must be implemented in subclass")
    }

    // New createSpeech method
    func createSpeech(request: LLMRequest, completion: @escaping (Swift.Result<Data, Error>) -> Void) {
        fatalError("createSpeech method must be implemented in subclass")
    }
}
