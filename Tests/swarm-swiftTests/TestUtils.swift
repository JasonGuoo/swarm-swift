import Foundation
@testable import swarm_swift

/**
 TestUtils

 This utility class provides helper methods for loading and masking configuration data
 used in the ClientFactoryTests.

 Setup Instructions for .env Files:
 1. Create a directory named 'config' in your home directory (~/).
 2. In the project's 'examples' directory, you will find example .env files for each LLM type.
    Copy these files to the ~/config/ directory you created. The files are:
    - .env.openai
    - .env.azureopenai
    - .env.ollama
    - .env.deepseek
    - .env.chatglm

 3. Edit each .env file in the ~/config/ directory, replacing the placeholder values
    with your actual API keys, base URLs, and other required information.

 4. Ensure that each .env file contains the necessary keys for its respective LLM type:

    For OpenAI:
    OpenAI_API_KEY=your_actual_api_key_here
    OpenAI_API_BASE_URL=https://api.openai.com/v1

    For Azure OpenAI:
    AzureOpenAI_API_KEY=your_azure_api_key_here
    AzureOpenAI_API_BASE_URL=https://your-resource-name.openai.azure.com
    AzureOpenAI_API_VERSION=2023-05-15
    AzureOpenAI_DEPLOYMENT_ID=your_deployment_id_here

    For Ollama:
    Ollama_API_KEY=your_ollama_api_key_here
    Ollama_API_BASE_URL=http://localhost:11434

    For DeepSeek:
    DeepSeek_API_KEY=your_deepseek_api_key_here
    DeepSeek_API_BASE_URL=https://api.deepseek.com

    For ChatGLM:
    ChatGLM_API_KEY=your_chatglm_api_key_here
    ChatGLM_API_BASE_URL=https://api.chatglm.com

 5. Ensure that you keep these .env files secure and never commit them to version control.

 Note: The loadConfig method in this class will attempt to read these .env files from
 the ~/config/ directory. Make sure the files are in place before running the tests.
 */


public class TestUtils {
    /**
     Loads the configuration for a specified API type from a .env file.
     
     - Parameter apiType: A string representing the API type (e.g., "openai", "azureopenai").
     - Returns: A Config object populated with the key-value pairs from the .env file.
     
     This function attempts to read a .env file from the user's home directory,
     specifically from ~/config/.env.<apitype>. It then parses the file contents
     and populates a Config object with the key-value pairs.
     */
    public static func loadConfig(for apiType: String) -> Config {
        let config = Config()
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configPath = homeDir.appendingPathComponent("config/.env.\(apiType.lowercased())")
        
        print("Attempting to load config from: \(configPath.path)")
        
        do {
            let contents = try String(contentsOf: configPath, encoding: .utf8)
            print("Successfully loaded .env file for \(apiType)")
            print("File contents (API keys masked):")
            print(maskAPIKeys(in: contents))
            
            let lines = contents.components(separatedBy: .newlines)
            
            for line in lines {
                let parts = line.components(separatedBy: "=")
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    config.setValue(forKey: key, value: value)
                }
            }
            
            print("Generated Config instance (API keys masked):")
            print(maskAPIKeys(in: config.description))
        } catch {
            print("Failed to load config for \(apiType): \(error)")
        }
        
        return config
    }
    
    /**
     Masks API keys in the given text to protect sensitive information.
     
     - Parameter text: A string containing configuration information, potentially including API keys.
     - Returns: A string with API keys masked for safe logging or display.
     
     This function identifies lines containing "api_key" (case-insensitive) and
     masks the corresponding values to protect sensitive information.
     */
    public static func maskAPIKeys(in text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let maskedLines = lines.map { line -> String in
            if line.lowercased().contains("api_key") {
                let parts = line.components(separatedBy: "=")
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    let maskedValue = maskValue(value)
                    return "\(key)=\(maskedValue)"
                }
            }
            return line
        }
        return maskedLines.joined(separator: "\n")
    }
    
    /**
     Masks a given value, typically used for API keys or other sensitive information.
     
     - Parameter value: The string value to be masked.
     - Returns: A masked version of the input string.
     
     If the input string is 8 characters or less, it replaces all characters with asterisks.
     For longer strings, it shows the first 4 characters, followed by "...", and then the last 4 characters.
     */
    static func maskValue(_ value: String) -> String {
        if value.count <= 8 {
            return String(repeating: "*", count: value.count)
        } else {
            let visiblePart = value.prefix(4) + "..." + value.suffix(4)
            return String(visiblePart)
        }
    }
}
