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
        history: [LLMMessage],
        contextVariables: [String: String],
        modelOverride: String?,
        stream: Bool? = false,
        debug: Bool? = false
    ) -> LLMResponse {
        let contextVariables = contextVariables.merging([:]) { (_, new) in new }
        let instructions = agent.instructions ?? "You are a helpful assistant."
        var messages = [LLMMessage(role: "system", content: instructions)] + history
        debugPrint(debug: debug ?? false, "Getting chat completion for...:", messages)

        let model = modelOverride != nil ? modelOverride! : agent.model
        
        var tools = agent.functions
        let toolChoice = tools.isEmpty ? "" : "auto"
        // create new messages with instructions
        let newMessage = LLMMessage(role: "system", content: instructions )
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



    public func handleToolCalls(
        agent: Agent,
        toolCalls: [LLMResponse.ToolCall],
        functions: [LLMRequest.Tool],
        contextVariables: [String: String],
        debug: Bool
    ) -> SwarmResult {
        var functionMap:[String: LLMRequest.Function] = [:]
        for rtool in functions {
            functionMap[rtool.function.name] = rtool.function
        }
        
        var partialResponse = SwarmResult(messages: [])

        for toolCall in toolCalls {
            let name = toolCall.function?.name
            guard let function : LLMRequest.Function = functionMap[name ?? ""] else {
                debugPrint(debug, "Tool \(name) not found in function map.")
                partialResponse.messages?.append(LLMMessage(role:"assistant", content: "Error: Tool \(name) not found."))
                continue
            }

            debugPrint(debug, "Processing tool call: \(name) with arguments \(toolCall.function?.arguments)")

            var arrayOfDictionaries:[String:Any] = [:]
            var args = toolCall.function?.arguments
            // Convert the JSON string to Data
            if let jsonData = args?.data(using: .utf8) {
                do {
                    // Deserialize the JSON data
                    let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])

                    // Cast the object to an array of dictionaries
                    if let arrayOfDictionaries = jsonObject as? [[String: Any]] {
                        // Now you have an array of [String: Any] dictionaries
                        for dictionary in arrayOfDictionaries {
                            print(dictionary)
                        }
                    } else {
                        print("Failed to cast JSON to [[String: Any]]")
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            } else {
                print("Error converting String to Data")
            }
            

            let rawResult: Any
            do {
                rawResult = try callFunction(on: agent, with: name ?? "", arguments: arrayOfDictionaries)
            } catch {
                debugPrint(debug, "Error calling function \(name ?? ""): \(error)")
                partialResponse.messages?.append(LLMMessage(role:"assistant", content: "Error: Failed to execute function \(name ?? ""). \(error.localizedDescription)"))
                continue
            }
            let result = handleFunctionResult(rawResult, debug: debug) 
        }

        return partialResponse
    }

    public func run(
        agent: Agent,
        messages: [LLMMessage],
        contextVariables: [String: String] = [:],
        modelOverride: String? = nil,
        stream: Bool = false,
        debug: Bool = false,
        maxTurns: Int = Int.max,
        executeTools: Bool = true
    ) -> SwarmResult {

        
        // TODO: stream is not suppored yet
        var is_stream = false
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
        var activeAgent = agent
        var contextVariables = contextVariables
        var history = messages
        let initLen = messages.count

        while (history.count - initLen < maxTurns) && activeAgent != nil {
            // Get completion with current history, agent
            let llmresponse = getChatCompletion(
                agent: activeAgent,
                history: history,
                contextVariables: contextVariables,
                modelOverride: modelOverride,
                stream: stream,
                debug: debug
            )

            guard let message = llmresponse.choices?.first?.message else {
                debugPrint(debug, "No message received in completion.")
                break
            }

            debugPrint(debug, "Received completion:", message)
            history.append(message)

            if message.getValue("tool_calls") == nil || !executeTools {
                debugPrint(debug, "Ending turn.")
                break
            }

            // Handle function calls, updating contextVariables, and switching agents
            let partialResponse = handleToolCalls(
                agent: activeAgent,
                toolCalls: message.getValue("tool_calls") as! [LLMResponse.ToolCall] ,
                functions: activeAgent.functions,
                contextVariables: contextVariables,
                debug: debug
            )

            if let messages = partialResponse.messages {
                history.append(contentsOf: messages)
            }
            
            if let newAgent = partialResponse.agent {
                activeAgent = newAgent
            }
        }

        return SwarmResult(
               messages: Array(history.dropFirst(initLen)),
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
               messages: [LLMMessage(role: "assistant", content: try!  agent.name)],
               agent: agent
           )
       default:
           do {
               return SwarmResult(messages: [LLMMessage(role: "assistant", content: String(describing: result))])
           } catch {
               let errorMessage = "Failed to cast response to string: \(result). Make sure agent functions return a string or Result object. Error: \(error)"
               debugPrint(debug, errorMessage)
               fatalError(errorMessage)
           }
       }
    }

}
