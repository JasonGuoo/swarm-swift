import Foundation
import SwiftyJSON

public class Swarm {
    public let client: LLMClient
    public let contextVariablesName: String

    public init(client: LLMClient, contextVariablesName: String = "context_variables") {
        self.client = client
        self.contextVariablesName = contextVariablesName
    }

    public func getChatCompletion(
        agent: Agent,
        history: Message,
        contextVariables: [String: String],
        modelOverride: String?,
        stream: Bool? = false,
        debug: Bool? = false
    ) -> Response {
        let contextVariables = contextVariables.merging([:]) { (_, new) in new }
        let instructions = agent.instructions ?? "You are a helpful assistant."
        var messages = [Message(["role": "system", "content": instructions])] + (history.json.array ?? [])
        debugPrint(debug: debug ?? false, "Getting chat completion for...:", messages)

        let model = modelOverride ?? agent.model
        
        let toolChoice = agent.functions != nil && !agent.functions!.isEmpty ? "auto" : ""
        
        let request = Request()
        request.withModel(model:model)
    
        request.appendMessage(message: history)
        
        request.withStream(stream ?? false)
        if let functions = agent.functions {
            request.withTools(functions.arrayValue.map { $0.dictionaryObject ?? [:] })
        }
        request.withToolChoice(["type": toolChoice])

        var response: Response?
        let semaphore = DispatchSemaphore(value: 0)

        client.createChatCompletion(request: request) { result in
            switch result {
            case .success(let llmResponse):
                response = llmResponse
            case .failure(let error):
                self.debugPrint(debug: debug ?? false, "Error in getChatCompletion:", error)
                response = Response(parseJSON: "{\"error\": {\"message\": \"\(error.localizedDescription)\"}}")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return response ?? Response(parseJSON: "{}")
    }

    public func handleToolCalls(
        agent: Agent,
        toolCalls: [JSON],
        functions: [JSON],
        contextVariables: [String: String],
        debug: Bool
    ) -> SwarmResult {
        var functionMap: [String: JSON] = [:]
        for function in functions {
            if let name = function["function"]["name"].string {
                functionMap[name] = function["function"]
            }
        }
        
        var partialResponse = SwarmResult(messages: JSON([]))

        for toolCall in toolCalls {
            let name = toolCall["function"]["name"].string
            guard let function = functionMap[name ?? ""] else {
                self.debugPrint(debug: debug ?? false, "Tool \(name ?? "") not found in function map.")
                partialResponse.messages?.arrayObject?.append(["role": "assistant", "content": "Error: Tool \(name ?? "") not found."])
                continue
            }

            self.debugPrint(debug: debug ?? false, "Processing tool call: \(name ?? "") with arguments \(toolCall["function"]["arguments"].stringValue)")

            let args = toolCall["function"]["arguments"].stringValue
            
            let rawResult: Any
            do {
                rawResult = try callFunction(agent: agent, functionName: name ?? "", arguments: args)
            } catch {
                self.debugPrint(debug: debug ?? false, "Error calling function \(name ?? ""): \(error)")
                partialResponse.messages?.arrayObject?.append(["role": "assistant", "content": "Error: Failed to execute function \(name ?? ""). \(error.localizedDescription)"])
                continue
            }
            
            let result = handleFunctionResult(rawResult, debug: debug)
            if let resultMessages = result.messages?.arrayValue {
                partialResponse.messages?.arrayObject?.append(contentsOf: resultMessages.map { $0.dictionaryObject ?? [:] })
            }
            if let resultAgent = result.agent {
                partialResponse.agent = resultAgent
            }
        }

        return partialResponse
    }

    public func run(
        agent: Agent,
        messages: Message,
        contextVariables: [String: String] = [:],
        modelOverride: String? = nil,
        stream: Bool = false,
        debug: Bool = false,
        maxTurns: Int = Int.max,
        executeTools: Bool = true
    ) -> SwarmResult {
        var activeAgent = agent
        var contextVariables = contextVariables
        var history = messages
        let initLen = history.json.array?.count ?? 0

        while ((history.json.array?.count ?? 0) - initLen < maxTurns) && activeAgent != nil {
            let llmresponse = getChatCompletion(
                agent: activeAgent,
                history: history,
                contextVariables: contextVariables,
                modelOverride: modelOverride,
                stream: stream,
                debug: debug
            )

            guard let message = llmresponse.getChoiceMessage(at: 0) else {
                self.debugPrint(debug: debug ?? false, "No message received in completion.")
                break
            }

            self.debugPrint(debug: debug ?? false, "Received completion:", message)
            history.json.arrayObject?.append(message.dictionaryObject ?? [:])

            if message["tool_calls"].isEmpty || !executeTools {
                self.debugPrint(debug: debug ?? false, "Ending turn.")
                break
            }

            let partialResponse = handleToolCalls(
                agent: activeAgent,
                toolCalls: message["tool_calls"].arrayValue,
                functions: activeAgent.functions?.arrayValue ?? [],
                contextVariables: contextVariables,
                debug: debug
            )

            if let messages = partialResponse.messages?.arrayValue {
                history.json.arrayObject?.append(contentsOf: messages.map { $0.dictionaryObject ?? [:] })
            }
            
            if let newAgent = partialResponse.agent {
                activeAgent = newAgent
            }
        }

        return SwarmResult(
            messages: JSON(history.json.arrayValue.dropFirst(initLen)),
            agent: activeAgent,
            contextVariables: contextVariables
        )
    }
    
    public func handleFunctionResult(_ result: Any, debug: Bool) -> SwarmResult {
        switch result {
        case let result as SwarmResult:
            return result
        case let agent as Agent:
            return SwarmResult(
                messages: JSON([["role": "assistant", "content": agent.name]]),
                agent: agent
            )
        default:
            do {
                return SwarmResult(messages: JSON([["role": "assistant", "content": String(describing: result)]]))
            } catch {
                let errorMessage = "Failed to cast response to string: \(result). Make sure agent functions return a string or Result object. Error: \(error)"
                self.debugPrint(debug: debug ?? false, errorMessage)
                fatalError(errorMessage)
            }
        }
    }

    // You'll need to implement this function
    private func callFunction(agent: Agent, functionName: String, arguments: String) throws -> Any {
        return try! callFunction(agent: agent, functionName: functionName, arguments: arguments)
    }

    private func debugPrint(debug: Bool, _ items: Any...) {
        if debug {
            print(items)
        }
    }
}
