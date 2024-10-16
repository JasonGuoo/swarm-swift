import Foundation

public enum LLMError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
    case unsupportedOperation(String)
    case httpError(statusCode: Int, data: Data)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .requestFailed:
            return "The request to the AI API failed"
        case .decodingFailed:
            return "Failed to decode the API response"
        case .unsupportedOperation(let message):
            return message
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        }
    }
}
