import Foundation

public class Swarm {
    public let client: LLMClient
    public let contextVariablesName: String

    public init(client: LLMClient, contextVariablesName: String = "context_variables") {
        self.client = client
        self.contextVariablesName = contextVariablesName
    }

    public func getChatCompletion(
        agent: Agent,
        history: [LLMRequest.Message],
        contextVariables: [String: String],
        modelOverride: String?,
        stream: Bool? = false,
        debug: Bool? = false
    ) -> LLMResponse {
        let contextVariables = contextVariables.merging([:]) { (_, new) in new }
        let instructions = agent.instructions ?? "You are a helpful assistant."
        var messages = [LLMRequest.Message(role: "system", content: instructions)] + history
        debugPrint(debug: debug ?? false, "Getting chat completion for...:", messages)

        let model = modelOverride != nil ? modelOverride! : agent.model
        
        var tools = agent.functions
        let toolChoice = tools.isEmpty ? "" : "auto"
        // create new messages with instructions
        let newMessage = LLMRequest.Message(role: "system", content: instructions )
        var newmessages = [newMessage]
        newmessages.append(contentsOf: messages)
        
        var request = LLMRequest(
            model: model,
            messages: newmessages,
            stream: stream,
            tools: tools,
            toolChoice:  toolChoice
        )

        var response: LLMResponse?
        let semaphore = DispatchSemaphore(value: 0)

        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let llmResponse):
                response = llmResponse
            case .failure(let error):
                debugPrint("Error in getChatCompletion:", error)
                response = LLMResponse(error: LLMResponse.APIError(message: error.localizedDescription))
            }
            semaphore.signal()
        }

        semaphore.wait()
        return response ?? LLMResponse()
    }

    public func handleFunctionResult(_ result: Any, debug: Bool) -> SwarmResult {
//        switch result {
//        case let result as SwarmResult:
//            return result
//        case let agent as Agent:
//            return SwarmResult(
//                value: try! JSONEncoder().encode(["assistant": agent.name]),
//                agent: agent
//            )
//        default:
//            do {
//                return SwarmResult(value: String(describing: result))
//            } catch {
//                let errorMessage = "Failed to cast response to string: \(result). Make sure agent functions return a string or Result object. Error: \(error)"
//                debugPrint(debug, errorMessage)
//                fatalError(errorMessage)
//            }
//        }
        
        // TODO: Implement the function logic later
        return SwarmResult(value: "", agent: nil, contextVariables: nil)
    }

    public func handleToolCalls(
        toolCalls: [LLMResponse.ToolCall],
        functions: [LLMRequest.Tool],
        contextVariables: [String: String],
        debug: Bool
    ) -> SwarmResult {
//        let functionMap = Dictionary(uniqueKeysWithValues: functions.map { ($0.name, $0) })
//        var partialResponse = SwarmResult(messages: [], agent: nil, contextVariables: [:])
//
//        for toolCall in toolCalls {
//            let name = toolCall.function?.name
//            guard let function = functionMap[name] else {
//                debugPrint(debug, "Tool \(name) not found in function map.")
//                partialResponse.messages.append(Message(
//                    role: .tool,
//                    content: "Error: Tool \(name) not found.",
//                    toolCallId: toolCall.id,
//                    toolName: name
//                ))
//                continue
//            }
//
//            debugPrint(debug, "Processing tool call: \(name) with arguments \(toolCall.function?.arguments)")
//
//            var args = try! JSONDecoder().decode([String: Any].self, from: toolCall.function?.arguments.data(using: .utf8)!)
//            if function.parameters.contains(where: { $0.name == self.contextVariablesName }) {
//                args[self.contextVariablesName] = contextVariables
//            }
//
//            let rawResult = function.execute(args)
//            let result = handleFunctionResult(rawResult, debug: debug)
//
//            partialResponse.messages.append(LLMResponse.Message(
//                role: "tool",
//                content: result.value,
//                toolCallId: toolCall.id,
//                toolName: name
//            ))
//            partialResponse.contextVariables.merge(result.contextVariables) { $1 }
//            if let newAgent = result.agent {
//                partialResponse.agent = newAgent
//            }
//        }
//
//        return partialResponse
        
        // TODO: Implement the function logic later
        return SwarmResult(value: "", agent: nil, contextVariables: nil)
    }

    public func run(
        agent: Agent,
        messages: [LLMRequest.Message],
        contextVariables: [String: String] = [:],
        modelOverride: String? = nil,
        stream: Bool = false,
        debug: Bool = false,
        maxTurns: Int = Int.max,
        executeTools: Bool = true
    ) -> LLMResponse {
//        if stream {
//            var finalResponse: Response?
//            runAndStream(
//                agent: agent,
//                messages: messages,
//                contextVariables: contextVariables,
//                modelOverride: modelOverride,
//                debug: debug,
//                maxTurns: maxTurns,
//                executeTools: executeTools
//            ) { chunk in
//                if case .response(let response) = chunk {
//                    finalResponse = response
//                }
//            }
//            // Wait for the async operation to complete
//            while finalResponse == nil {
//                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
//            }
//            return finalResponse!
//        }
//
//        var activeAgent = agent
//        var contextVariables = contextVariables
//        var history = messages
//        let initLen = messages.count
//
//        while history.count - initLen < maxTurns, activeAgent != nil {
//            // Get completion with current history, agent
//            let completion = getChatCompletion(
//                agent: activeAgent,
//                history: history,
//                contextVariables: contextVariables,
//                modelOverride: modelOverride,
//                stream: stream,
//                debug: debug
//            )
//
//            guard let message = completion.choices.first?.message else {
//                break
//            }
//
//            debugPrint(debug, "Received completion:", message)
//            var messageDict = message.dictionary
//            messageDict["sender"] = activeAgent.name
//
//            if let jsonData = try? JSONSerialization.data(withJSONObject: messageDict),
//               let jsonMessage = try? JSONDecoder().decode(Message.self, from: jsonData) {
//                history.append(jsonMessage)
//            }
//
//            if message.toolCalls == nil || !executeTools {
//                debugPrint(debug, "Ending turn.")
//                break
//            }
//
//            // Handle function calls, updating contextVariables, and switching agents
//            let partialResponse = handleToolCalls(
//                toolCalls: message.toolCalls ?? [],
//                functions: activeAgent.functions,
//                contextVariables: contextVariables,
//                debug: debug
//            )
//
//            history.append(contentsOf: partialResponse.messages)
//            contextVariables.merge(partialResponse.contextVariables) { $1 }
//            if let newAgent = partialResponse.agent {
//                activeAgent = newAgent
//            }
//        }
//
//        return Response(
//            messages: Array(history.dropFirst(initLen)),
//            agent: activeAgent,
//            contextVariables: contextVariables
//        )
        // TODO: Implement the function logic later
        return LLMResponse(
            
        )
    }

    // 辅助类型定义
    public enum StreamChunk {
//        case start
//        case delta(StreamDelta)
//        case end
//        case response(Response)
    }

    public struct StreamDelta: Codable {
//        var content: String?
//        var sender: String?
//        var role: MessageRole?
//        var functionCall: FunctionCall?
//        var toolCalls: [ToolCall]?
//
//        init(from delta: ChatCompletionChunkChoice.Delta) {
//            self.content = delta.content
//            self.role = delta.role
//            self.functionCall = delta.functionCall
//            self.toolCalls = delta.toolCalls
//        }
    }

    // 辅助函数
    // private func mergeChunk(_ message: inout Message, delta: StreamDelta) {
//        if let content = delta.content {
//            message.content += content
//        }
//        if let sender = delta.sender {
//            message.sender = sender
//        }
//        if let role = delta.role {
//            message.role = role
//        }
//        if let functionCall = delta.functionCall {
//            message.functionCall = functionCall
//        }
//        if let toolCalls = delta.toolCalls {
//            for toolCall in toolCalls {
//                if message.toolCalls[toolCall.id] == nil {
//                    message.toolCalls[toolCall.id] = toolCall
//                } else {
//                    message.toolCalls[toolCall.id]?.merge(with: toolCall)
//                }
//            }
//        }
    // }
}
