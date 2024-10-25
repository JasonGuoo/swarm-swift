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
        history: [Message],
        contextVariables: [String: String],
        modelOverride: String?,
        stream: Bool? = false,
        debug: Bool? = false
    ) -> Response {
        let contextVariables = contextVariables.merging([:]) { (_, new) in new }
        let instructions = agent.instructions ?? "You are a helpful assistant."
//        var messages = [Message(["role": "system", "content": instructions])] + (history.json.array ?? [])
//        debugPrint(debug: debug ?? false, "Getting chat completion for...:", messages)

        let model = modelOverride ?? agent.model
        
        let toolChoice = agent.functions != nil && !agent.functions!.isEmpty ? "auto" : ""
        
        let request = Request()
        request.withModel(model:model)
    
        request.appendMessages(messages: history)
        
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
        
        var partialResponse = SwarmResult(messages: [Message()])

        for toolCall in toolCalls {
            let name = toolCall["function"]["name"].string
            guard let function = functionMap[name ?? ""] else {
                self.debugPrint(debug: debug ?? false, "Tool \(name ?? "") not found in function map.")
                let errorMessage = Message()
                errorMessage.withRole(role: "assistant").withContent(content: "Error: Tool \(name ?? "") not found.")
                partialResponse.messages?.append(errorMessage)
                continue
            }

            self.debugPrint(debug: debug ?? false, "Processing tool call: \(name ?? "") with arguments \(toolCall["function"]["arguments"].stringValue)")

            let args = toolCall["function"]["arguments"].stringValue
            
            let rawResult: Any
            do {
                rawResult = try callFunction(agent: agent, functionName: name ?? "", arguments: args)
            } catch {
                self.debugPrint(debug: debug ?? false, "Error calling function \(name ?? ""): \(error)")
                let errorMessage = Message()
                errorMessage.withRole(role: "assistant").withContent(content: "Error: Failed to execute function \(name ?? ""). \(error.localizedDescription)")
                partialResponse.messages?.append(errorMessage)
                continue
            }
            
            let result = handleFunctionResult(rawResult, debug: debug)
            if let resultMessages = result.messages {
                for resultMessage in resultMessages {
                    partialResponse.messages?.append(resultMessage)
                }
            }
            if let resultAgent = result.agent {
                partialResponse.agent = resultAgent
            }
        }

        return partialResponse
    }

    public func run(
        agent: Agent,
        messages: [Message],
        contextVariables: [String: String] = [:],
        modelOverride: String? = nil,
        stream: Bool = false,
        debug: Bool = false,
        maxTurns: Int = 10,
        executeTools: Bool = true
    ) -> SwarmResult {
        var activeAgent = agent
        var contextVariables = contextVariables
        var history = messages
        let initLen = history.count

        while (history.count - initLen < maxTurns) && activeAgent != nil {
            let llmresponse = getChatCompletion(
                agent: activeAgent,
                history: history,
                contextVariables: contextVariables,
                modelOverride: modelOverride,
                stream: stream,
                debug: debug
            )

            guard let messageJSON = llmresponse.getChoiceMessage(at: 0) else {
                self.debugPrint(debug: debug ?? false, "No message received in completion.")
                break
            }

            self.debugPrint(debug: debug ?? false, "Received completion:", messageJSON)
            let message = Message(messageJSON)
            history.append(message)

            if messageJSON["tool_calls"].isEmpty || !executeTools {
                self.debugPrint(debug: debug ?? false, "Ending turn.")
                break
            }

            let partialResponse = handleToolCalls(
                agent: activeAgent,
                toolCalls: messageJSON["tool_calls"].arrayValue,
                functions: activeAgent.functions?.arrayValue ?? [],
                contextVariables: contextVariables,
                debug: debug
            )

            if let messages = partialResponse.messages {
                for mm in messages {
                    history.append(mm)
                }
            }
            
            if let newAgent = partialResponse.agent {
                activeAgent = newAgent
            }
        }

        return SwarmResult(
            messages: history,
            agent: activeAgent,
            contextVariables: contextVariables
        )
    }
    
    public func handleFunctionResult(_ result: Any, debug: Bool) -> SwarmResult {
        switch result {
        case let result as SwarmResult:
            return result
        case let agent as Agent:
            let message = Message()
            message.withRole(role: "assistant").withContent(content: agent.name)
            return SwarmResult(
                messages: [message],
                agent: agent
            )
        default:
            do {
                let message = Message()
                message.withRole(role: "assistant").withContent(content: String(describing: result))
                return SwarmResult(messages: [message])
            } catch {
                let errorMessage = "Failed to cast response to string: \(result). Make sure agent functions return a string or Result object. Error: \(error)"
                self.debugPrint(debug: debug ?? false, errorMessage)
                fatalError(errorMessage)
            }
        }
    }

    private func debugPrint(debug: Bool, _ items: Any...) {
        if debug {
            print(items)
        }
    }
}
