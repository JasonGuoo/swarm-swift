import Foundation

public class AzureOpenAIClient: OpenAIClient {
    public let endpoint: String
    public let apiVersion: String
    public let deploymentId: String
    
    public init(apiKey: String, endpoint: String, apiVersion: String, deploymentId: String) {
        self.endpoint = endpoint
        self.apiVersion = apiVersion
        self.deploymentId = deploymentId
        super.init(apiKey: apiKey, baseURL: endpoint)
    }
    
    override internal func performRequest(request: LLMRequest, endpoint: String, completion: @escaping (Result<LLMResponse, Error>) -> Void) {
        // Construct the Azure-specific endpoint URL
        let azureEndpoint = "\(self.endpoint)/openai/deployments/\(deploymentId)/chat/completions?api-version=\(apiVersion)"
        
        // Ensure the endpoint URL is valid
        guard let url = URL(string: azureEndpoint) else {
            completion(.failure(LLMError.invalidURL))
            return
        }

        // Set up the URLRequest with necessary headers
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")

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

        // Log request details for debugging
        DebugUtils.printDebug("AzureOpenAIClient - Request URL: \(url.absoluteString)")
        DebugUtils.printDebugHeaders(urlRequest.allHTTPHeaderFields ?? [:])

        // Create and start the network request
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            // Handle network errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Ensure we received a valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LLMError.requestFailed))
                return
            }
            
            // Ensure we received data
            guard let data = data else {
                completion(.failure(LLMError.requestFailed))
                return
            }
            
            // Log response details for debugging
            DebugUtils.printDebug("AzureOpenAIClient - Response Status Code: \(httpResponse.statusCode)")
            DebugUtils.printDebugJSON(data)
            
            // Check if the request was successful (status code 200)
            if httpResponse.statusCode == 200 {
                // Convert data to JSON string
                guard let jsonString = String(data: data, encoding: .utf8) else {
                    completion(.failure(LLMError.decodingFailed))
                    return
                }
                
                // Parse the JSON response using LLMResponse.fromJSON
                let result = LLMResponse.fromJSON(jsonString)
                switch result {
                case .success(let llmResponse):
                    completion(.success(llmResponse))
                case .failure(let error):
                    DebugUtils.printDebug("Decoding Error: \(error.localizedDescription)")
                    completion(.failure(LLMError.decodingFailed))
                }
            } else {
                // Handle non-200 status codes
                completion(.failure(LLMError.httpError(statusCode: httpResponse.statusCode, data: data)))
            }
        }

        // Start the network request
        task.resume()
    }
}
