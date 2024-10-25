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
    
    override internal func performRequest(request: Request, endpoint: String, completion: @escaping (Result<Response, Error>) -> Void) {
        // Construct the Azure-specific endpoint URL
        let azureEndpoint = "\(self.endpoint)/openai/deployments/\(deploymentId)/chat/completions?api-version=\(apiVersion)"
        
        // Ensure the endpoint URL is valid
        guard let url = URL(string: azureEndpoint) else {
            completion(.failure(NSError(domain: "AzureOpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        // Set up the URLRequest with necessary headers
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "api-key")

        // Encode the request body
        do {
            let jsonData = try request.rawData()
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
                completion(.failure(NSError(domain: "AzureOpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                return
            }
            
            // Ensure we received data
            guard let data = data else {
                completion(.failure(NSError(domain: "AzureOpenAIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Log response details for debugging
            DebugUtils.printDebug("AzureOpenAIClient - Response Status Code: \(httpResponse.statusCode)")
            DebugUtils.printDebugJSON(data)
            
            // Check if the request was successful (status code 200)
            if httpResponse.statusCode == 200 {
                // Parse the JSON response
                do {
                    let response = try Response(data: data)
                    completion(.success(response))
                } catch {
                    DebugUtils.printDebug("Decoding Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } else {
                // Handle non-200 status codes
                completion(.failure(NSError(domain: "AzureOpenAIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error", "data": data])))
            }
        }

        // Start the network request
        task.resume()
    }
}
