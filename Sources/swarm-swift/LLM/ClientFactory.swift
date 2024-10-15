import Foundation

public class ClientFactory {
    /// Creates an LLM client based on the specified API type and configuration.
    /// If no config is provided, it tries to load from .env file, then falls back to environment variables.
    /// - Parameters:
    ///   - apiType: The type of LLM API to use. Defaults to "OpenAI".
    ///   - config: An optional Config instance. If provided, it takes precedence over .env and environment variables.
    /// - Returns: An LLMClient instance if successful, nil otherwise.
    public static func getLLMClient(apiType: String? = nil, config: Config? = nil) -> LLMClient? {
        let configSource: ConfigSource
        var finalApiType = apiType
        
        if let providedConfig = config {
            configSource = .config(providedConfig)
        } else if let envConfig = loadFromEnvFile() {
            configSource = .config(envConfig)
        } else if let envVarConfig = generateConfigFromEnvironment() {
            configSource = .config(envVarConfig)
            finalApiType = finalApiType ?? envVarConfig.value(forKey: "API_TYPE")
        } else {
            configSource = .environment
        }
        
        finalApiType = finalApiType ?? "OpenAI"  // Default to OpenAI if still not set
        
        return createClient(apiType: finalApiType!, from: configSource)
    }
    
    /// Creates an LLM client using configuration from a .env file in the current directory.
    /// - Parameter apiType: The type of LLM API to use. Defaults to "OpenAI".
    /// - Returns: An LLMClient instance if .env file is found and parsed successfully, nil otherwise.
    public static func getFromEnv(apiType: String = "OpenAI") -> LLMClient? {
        guard let envConfig = loadFromEnvFile() else {
            return nil
        }
        return getLLMClient(apiType: apiType, config: envConfig)
    }

    /// Creates an LLM client using configuration from environment variables.
    /// - Parameter apiType: The type of LLM API to use. Defaults to "OpenAI".
    /// - Returns: An LLMClient instance based on environment variables.
    public static func getFromEnvironmentVariables(apiType: String = "OpenAI") -> LLMClient? {
        let configSource: ConfigSource = .environment
        return createClient(apiType: apiType, from: configSource)
    }

    /// Creates an LLM client using a provided Config instance.
    /// - Parameters:
    ///   - apiType: The type of LLM API to use. Defaults to "OpenAI".
    ///   - config: A Config instance containing the necessary configuration.
    /// - Returns: An LLMClient instance based on the provided configuration.
    public static func getFromConfig(apiType: String = "OpenAI", config: Config) -> LLMClient? {
        return getLLMClient(apiType: apiType, config: config)
    }

    private static func createClient(apiType: String, from source: ConfigSource) -> LLMClient? {
        switch apiType {
        case "OpenAI":
            return createOpenAIClient(from: source)
        case "AzureOpenAI":
            return createAzureOpenAIClient(from: source)
        case "Ollama":
            return createOllamaClient(from: source)
        case "DeepSeek":
            return createDeepSeekClient(from: source)
        case "ChatGLMAPI", "ChatGLM":
            return createChatGLMClient(from: source)
        default:
            return createOpenAIClient(from: source)
        }
    }
    
    private static func loadFromEnvFile() -> Config? {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let envFilePath = currentPath + "/.env"
        
        guard fileManager.fileExists(atPath: envFilePath),
              let contents = try? String(contentsOfFile: envFilePath, encoding: .utf8) else {
            return nil
        }
        
        let config = Config()
        let lines = contents.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") else {
                continue // Skip empty lines and comments
            }
            
            let components = trimmedLine.split(separator: "=", maxSplits: 1)
            guard components.count == 2 else {
                continue // Skip invalid lines
            }
            
            let key = String(components[0]).trimmingCharacters(in: .whitespaces)
            let value = String(components[1]).trimmingCharacters(in: .whitespaces)
            
            let cleanedValue = value.removingQuotes()
            
            config.setValue(forKey: key, value: cleanedValue)
        }
        
        return config.isEmpty() ? nil : config
    }
    
    private static func createOpenAIClient(from source: ConfigSource) -> OpenAIClient? {
        let apiKey = getValue(for: "OpenAI_API_KEY", from: source)
        let baseURL = getValue(for: "OpenAI_API_BASE_URL", from: source)
        
        guard let apiKey = apiKey, let baseURL = baseURL else { return nil }
        return OpenAIClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    private static func createAzureOpenAIClient(from source: ConfigSource) -> AzureOpenAIClient? {
        let apiKey = getValue(for: "AzureOpenAI_API_KEY", from: source)
        let baseURL = getValue(for: "AzureOpenAI_API_BASE_URL", from: source)
        let apiVersion = getValue(for: "AzureOpenAI_API_VERSION", from: source)
        let deploymentId = getValue(for: "AzureOpenAI_DEPLOYMENT_ID", from: source)
        
        guard let apiKey = apiKey, let baseURL = baseURL,
              let apiVersion = apiVersion, let deploymentId = deploymentId else { return nil }
        return AzureOpenAIClient(apiKey: apiKey, baseURL: baseURL, apiVersion: apiVersion, deploymentId: deploymentId)
    }
    
    private static func createOllamaClient(from source: ConfigSource) -> OllamaClient? {
        let apiKey = getValue(for: "Ollama_API_KEY", from: source)
        let baseURL = getValue(for: "Ollama_API_BASE_URL", from: source)
        
        guard let apiKey = apiKey, let baseURL = baseURL else { return nil }
        return OllamaClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    private static func createDeepSeekClient(from source: ConfigSource) -> DeepSeekClient? {
        let apiKey = getValue(for: "DeepSeek_API_KEY", from: source)
        let baseURL = getValue(for: "DeepSeek_API_BASE_URL", from: source)
        
        guard let apiKey = apiKey, let baseURL = baseURL else { return nil }
        return DeepSeekClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    private static func createChatGLMClient(from source: ConfigSource) -> ChatGLMClient? {
        let apiKey = getValue(for: "ChatGLM_API_KEY", from: source)
        let baseURL = getValue(for: "ChatGLM_API_BASE_URL", from: source)
        
        guard let apiKey = apiKey, let baseURL = baseURL else { return nil }
        return ChatGLMClient(apiKey: apiKey, baseURL: baseURL)
    }
    
    private static func getValue(for key: String, from source: ConfigSource) -> String? {
        switch source {
        case .config(let config):
            return config.value(forKey: key)
        case .environment:
            return ProcessInfo.processInfo.environment[key]
        }
    }
    
    internal static func generateConfigFromEnvironment() -> Config? {
        let config = Config()
        let relevantKeys = [
            "API_TYPE",  // New key for API type
            "OpenAI_API_KEY", "OpenAI_API_BASE_URL",
            "AzureOpenAI_API_KEY", "AzureOpenAI_API_BASE_URL", "AzureOpenAI_API_VERSION", "AzureOpenAI_DEPLOYMENT_ID",
            "Ollama_API_KEY", "Ollama_API_BASE_URL",
            "DeepSeek_API_KEY", "DeepSeek_API_BASE_URL",
            "ChatGLM_API_KEY", "ChatGLM_API_BASE_URL"
        ]
        
        for key in relevantKeys {
            if let value = ProcessInfo.processInfo.environment[key] {
                config.setValue(forKey: key, value: value)
            }
        }
        
        // If API_TYPE is not set in environment variables, set it to "OpenAI"
        if config.value(forKey: "API_TYPE") == nil {
            config.setValue(forKey: "API_TYPE", value: "OpenAI")
        }
        
        return config.isEmpty() ? nil : config
    }

    /// Creates a default LLM client based on available configuration.
    /// It checks environment variables and .env file, defaulting to OpenAI if no specific configuration is found.
    /// - Returns: An LLMClient instance if successful, nil otherwise.
    public static func getDefaultClient() -> LLMClient? {
        if let envConfig = generateConfigFromEnvironment() {
            let apiType = envConfig.value(forKey: "API_TYPE") ?? "OpenAI"
            return getLLMClient(apiType: apiType, config: envConfig)
        } else if let envFileConfig = loadFromEnvFile() {
            let apiType = envFileConfig.value(forKey: "API_TYPE") ?? "OpenAI"
            return getLLMClient(apiType: apiType, config: envFileConfig)
        } else {
            // If no configuration is found, default to OpenAI with environment variables
            return getFromEnvironmentVariables(apiType: "OpenAI")
        }
    }
}

private enum ConfigSource {
    case config(Config)
    case environment
}

private extension String {
    func removingQuotes() -> String {
        var result = self
        if result.hasPrefix("\"") && result.hasSuffix("\"") {
            result.removeFirst()
            result.removeLast()
        } else if result.hasPrefix("'") && result.hasSuffix("'") {
            result.removeFirst()
            result.removeLast()
        }
        return result
    }
}
