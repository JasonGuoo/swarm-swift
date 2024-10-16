# swarm-swift

swarm-swift is a Swift implementation of OpenAI's open-source AI agents framework, Swarm. This project aims to provide a flexible and powerful tool for orchestrating multiple AI agents in Swift applications.

## Overview

Inspired by [OpenAI's Swarm framework](https://github.com/openai/swarm) and the concepts outlined in the [Orchestrating Agents cookbook](https://cookbook.openai.com/examples/orchestrating_agents), swarm-swift brings the power of multi-agent AI systems to the Swift ecosystem.

Key features:
- Swift implementation of Swarm's core concepts
- Support for multiple LLM APIs, not just OpenAI
- Flexible agent orchestration
- Easy integration into Swift projects
- Basic chat.completion API calls for Swift users

## Status

⚠️ **Note:** This project is currently under active development. While we're working hard to implement and test all features, it's not yet ready for production use.

Current status:
- OpenAI and Azure OpenAI clients are now functional and ready for use.

## Supported LLM Clients

swarm-swift aims to support various Language Model APIs. Currently, we're working on integrating:

- OpenAI (✅ Available)
- Azure OpenAI (✅ Available)
- Ollama
- DeepSeek
- ChatGLM

More may be added in the future based on community needs and contributions.

## Getting Started

### Basic Chat Completion Usage

swarm-swift provides a simple way to make chat.completion API calls to large language models. Here's how you can use it:

1. Import the necessary modules:
The swarm-swift does not depend on any other frameworks, so you can just import the package into your project.
2. Create an LLMRequest:

The `LLMRequest` class is the core component for making chat completion requests. It encapsulates all the necessary information for an LLM API call. It will capture all the information needed for a chat completion request. It can be created by using the `LLMRequest.create` method, or from a JSON string using the `LLMRequest.fromJSONString(_:)` method. Here's how to create a basic LLMRequest:

The `LLMRequest` initializer takes several parameters:

- `model`: The name of the LLM model you want to use (e.g., "gpt-3.5-turbo").
- `messages`: An array of `LLMChatMessage` objects representing the conversation history.
- `temperature`: (Optional) Controls randomness in the output. Default is 1.0.
- `topP`: (Optional) An alternative to temperature, controls diversity of output. Default is 1.0.
- `n`: (Optional) Number of chat completion choices to generate. Default is 1.
- `stop`: (Optional) Up to 4 sequences where the API will stop generating further tokens.
- `maxTokens`: (Optional) The maximum number of tokens to generate.
- `presencePenalty`: (Optional) Penalizes new tokens based on their presence in the text so far. Default is 0.
- `frequencyPenalty`: (Optional) Penalizes new tokens based on their frequency in the text so far. Default is 0.
- `stream`: (Optional) Whether to stream the response. Default is false.
- `additionalParameters`: (Optional) Additional parameters to pass to the LLM API. This is a dictionary that will be converted to JSON and passed to the API.
- `tools`: (Optional) An array of `LLMFunctionDefinition` objects representing the tools that the LLM can use. This is used for tool calling.
- etc...

You can customize these parameters based on your specific needs.

3. Create an LLMClient:

The `LLMClient` protocol defines the interface for making chat completion requests. There is a factory method `LLMClient.getClient(apiType:config:)` that will return the correct LLMClient based on the `apiType` and `config` provided.

4. Make a chat completion request:

Use the `createChatCompletion(request:completionHandler:)` method to make a chat completion request. For example:

```swift
let config = TestUtils.loadConfig(for: "azureopenai") // or "openai" or "ollama" or "deepseek" or "chatglm", read it from file, etc...
let request = LLMRequest.create(model: "gpt-3.5-turbo", messages: [["role": "user", "content": "Hello, world!"]]) // or use request.fromJSONString(jsonString) to create a request from a json string
let client = LLMClient.getClient(apiType: "OpenAI", config: config) // or "azureopenai" etc...
// send the request
client.createChatCompletion(request: request) { result in
    switch result {
    case .success(let response):
    // handle the response
        print("Chat completion response: \(response)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Contributing

We welcome contributions! If you're interested in helping develop swarm-swift, please check our issues page or submit a pull request.

## License

(Include license information)

## Acknowledgements

This project is based on the work done by OpenAI on their [Swarm framework](https://github.com/openai/swarm). We're grateful for their innovative approach to multi-agent AI systems.

## Contact

