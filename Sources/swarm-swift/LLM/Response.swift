import Foundation
import SwiftyJSON

/**
 Response class for handling LLM API responses.

 This class provides methods to easily access and interpret the various components
 of an LLM API response, including choices, usage statistics, and potential errors.

 Note: While this Response class is primarily designed for OpenAI API responses,
 it can potentially be used with other LLM APIs due to the common JSON structure.
 However, users should exercise caution when using this class with non-OpenAI APIs,
 as the exact structure and keys may vary. Always verify the response structure
 of the specific LLM API you're using and access the correct values using the
 appropriate keys.

 Example API Responses:

 1. Chat Completion Response:
 {
   "id": "chatcmpl-123",
   "object": "chat.completion",
   "created": 1677652288,
   "model": "gpt-4o-mini",
   "system_fingerprint": "fp_44709d6fcb",
   "choices": [{
     "index": 0,
     "message": {
       "role": "assistant",
       "content": "\n\nHello there, how may I assist you today?",
     },
     "logprobs": null,
     "finish_reason": "stop"
   }],
   "usage": {
     "prompt_tokens": 9,
     "completion_tokens": 12,
     "total_tokens": 21,
     "completion_tokens_details": {
       "reasoning_tokens": 0
     }
   }
 }

 Code examples for Chat Completion Response:

 Example 1: Accessing basic information
 ```swift
 let response = Response(parseJSON: jsonString)
 print("Response ID: \(response.getId() ?? "N/A")")
 print("Model: \(response.getModel() ?? "N/A")")
 print("Total Tokens: \(response.getUsageTotalTokens() ?? 0)")
 ```

 Example 2: Accessing the assistant's message
 ```swift
 let response = Response(parseJSON: jsonString)
 if let content = response.getChoiceMessage(at: 0)?["content"].string {
     print("Assistant's response: \(content)")
 }
 ```

 2. Function Call Response:
 {
   "id": "chatcmpl-123",
   "object": "chat.completion",
   "created": 1677652288,
   "model": "gpt-4o-mini",
   "system_fingerprint": "fp_44709d6fcb",
   "choices": [{
     "index": 0,
     "message": {
       "role": "assistant",
       "content": null,
       "function_call": {
         "name": "get_current_weather",
         "arguments": "{\n  \"location\": \"Boston, MA\"\n}"
       }
     },
     "logprobs": null,
     "finish_reason": "function_call"
   }],
   "usage": {
     "prompt_tokens": 82,
     "completion_tokens": 18,
     "total_tokens": 100
   }
 }

 Code examples for Function Call Response:

 Example 1: Accessing function call information
 ```swift
 let response = Response(parseJSON: jsonString)
 if let functionName = response.getChoiceFunctionCallName(at: 0) {
     print("Function called: \(functionName)")
 }
 if let arguments = response.getChoiceFunctionCallArguments(at: 0) {
     print("Function arguments: \(arguments)")
 }
 ```

 Example 2: Checking finish reason and usage
 ```swift
 let response = Response(parseJSON: jsonString)
 print("Finish reason: \(response.getChoiceFinishReason(at: 0) ?? "N/A")")
 print("Prompt tokens: \(response.getUsagePromptTokens() ?? 0)")
 print("Completion tokens: \(response.getUsageCompletionTokens() ?? 0)")
 ```
*/
public class Response: MessageBase, CustomStringConvertible {
    
    enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case model
        case choices
        case usage
        case systemFingerprint = "system_fingerprint"
        case error
        case functionCall = "function_call"
        case completionTokensDetails = "completion_tokens_details"
        case toolCalls = "tool_calls"
    }
    
    /// Returns the unique identifier for this response.
    public func getId() -> String? {
        return json[CodingKeys.id.rawValue].string
    }
    
    /// Returns the object type of the response (e.g., "chat.completion").
    public func getObject() -> String? {
        return json[CodingKeys.object.rawValue].string
    }
    
    /// Returns the Unix timestamp of when the response was created.
    public func getCreated() -> Int? {
        return json[CodingKeys.created.rawValue].int
    }
    
    /// Returns the model used to generate the response.
    public func getModel() -> String? {
        return json[CodingKeys.model.rawValue].string
    }
    
    /// Returns an array of all choices in the response.
    public func getChoices() -> [JSON]? {
        return json[CodingKeys.choices.rawValue].array
    }
    
    /// Returns the usage statistics for this response.
    public func getUsage() -> JSON? {
        return json[CodingKeys.usage.rawValue]
    }
    
    /// Returns the system fingerprint, if available.
    public func getSystemFingerprint() -> String? {
        return json[CodingKeys.systemFingerprint.rawValue].string
    }
    
    /// Returns error information, if an error occurred.
    public func getError() -> JSON? {
        return json[CodingKeys.error.rawValue]
    }
    
    /// Returns the index of a specific choice.
    /// - Parameter index: The index of the choice to retrieve.
    /// - Returns: The index of the choice, or nil if the index is invalid.
    public func getChoiceIndex(at index: Int) -> Int? {
        guard isValidChoiceIndex(index) else { return nil }
        return json[CodingKeys.choices.rawValue][index]["index"].int
    }
    
    /// Returns the message of a specific choice.
    /// - Parameter index: The index of the choice to retrieve.
    /// - Returns: The message of the choice, or nil if the index is invalid.
    public func getChoiceMessage(at index: Int) -> JSON? {
        guard isValidChoiceIndex(index) else { return nil }
        return json[CodingKeys.choices.rawValue][index]["message"]
    }
    
    /// Returns the finish reason of a specific choice.
    /// - Parameter index: The index of the choice to retrieve.
    /// - Returns: The finish reason of the choice, or nil if the index is invalid.
    public func getChoiceFinishReason(at index: Int) -> String? {
        guard isValidChoiceIndex(index) else { return nil }
        return json[CodingKeys.choices.rawValue][index]["finish_reason"].string
    }
    
    /// Returns the number of prompt tokens used.
    public func getUsagePromptTokens() -> Int? {
        return json[CodingKeys.usage.rawValue]["prompt_tokens"].int
    }
    
    /// Returns the number of completion tokens used.
    public func getUsageCompletionTokens() -> Int? {
        return json[CodingKeys.usage.rawValue]["completion_tokens"].int
    }
    
    /// Returns the total number of tokens used.
    public func getUsageTotalTokens() -> Int? {
        return json[CodingKeys.usage.rawValue]["total_tokens"].int
    }
    
    /// Returns the error message, if an error occurred.
    public func getErrorMessage() -> String? {
        return json[CodingKeys.error.rawValue]["message"].string
    }
    
    /// Returns the error type, if an error occurred.
    public func getErrorType() -> String? {
        return json[CodingKeys.error.rawValue]["type"].string
    }
    
    /// Returns the error parameter, if an error occurred.
    public func getErrorParam() -> String? {
        return json[CodingKeys.error.rawValue]["param"].string
    }
    
    /// Returns the error code, if an error occurred.
    public func getErrorCode() -> String? {
        return json[CodingKeys.error.rawValue]["code"].string
    }
    
    /// Returns the function call information for a specific choice.
    /// - Parameter index: The index of the choice to retrieve.
    /// - Returns: The function call information, or nil if not available or the index is invalid.
    public func getChoiceFunctionCall(at index: Int) -> JSON? {
        guard isValidChoiceIndex(index) else { return nil }
        return json[CodingKeys.choices.rawValue][index]["message"][CodingKeys.functionCall.rawValue]
    }
    
    /// Returns the name of the function call for a specific choice.
    /// - Parameter index: The index of the choice to retrieve.
    /// - Returns: The function call name, or nil if not available or the index is invalid.
    public func getChoiceFunctionCallName(at index: Int) -> String? {
        guard isValidChoiceIndex(index) else { return nil }
        return getChoiceFunctionCall(at: index)?["name"].string
    }
    
    /// Returns the arguments of the function call for a specific choice.
    /// - Parameter index: The index of the choice to retrieve.
    /// - Returns: The function call arguments, or nil if not available or the index is invalid.
    public func getChoiceFunctionCallArguments(at index: Int) -> String? {
        guard isValidChoiceIndex(index) else { return nil }
        return getChoiceFunctionCall(at: index)?["arguments"].string
    }
    
    /// Returns the completion tokens details.
    public func getUsageCompletionTokensDetails() -> JSON? {
        return json[CodingKeys.usage.rawValue][CodingKeys.completionTokensDetails.rawValue]
    }
    
    /// Returns the number of reasoning tokens used, if available.
    public func getUsageReasoningTokens() -> Int? {
        return getUsageCompletionTokensDetails()?["reasoning_tokens"].int
    }
    
    /// Returns a string representation of the response for debugging purposes.
    public var description: String {
        var desc = "LLMResponse:\n"
        if let id = getId() { desc += "  ID: \(id)\n" }
        if let object = getObject() { desc += "  Object: \(object)\n" }
        if let created = getCreated() { desc += "  Created: \(created)\n" }
        if let model = getModel() { desc += "  Model: \(model)\n" }
        if let choices = getChoices() {
            desc += "  Choices (Count: \(getChoicesCount())):\n"
            for (index, choice) in choices.enumerated() {
                if let choiceIndex = getChoiceIndex(at: index) { desc += "    Index: \(choiceIndex)\n" }
                if let message = getChoiceMessage(at: index) {
                    desc += "    Message: \(message)\n"
                }
                if let finishReason = getChoiceFinishReason(at: index) {
                    desc += "    Finish Reason: \(finishReason)\n"
                }
                if let functionCall = getChoiceFunctionCall(at: index) {
                    desc += "    Function Call:\n"
                    if let name = getChoiceFunctionCallName(at: index) {
                        desc += "      Name: \(name)\n"
                    }
                    if let arguments = getChoiceFunctionCallArguments(at: index) {
                        desc += "      Arguments: \(arguments)\n"
                    }
                }
                let toolCallsCount = getToolCallsCount(at: index)
                if toolCallsCount > 0 {
                    desc += "    Tool Calls (Count: \(toolCallsCount)):\n"
                    for toolCallIndex in 0..<toolCallsCount {
                        if let id = getToolCallId(at: index, toolCallIndex: toolCallIndex) {
                            desc += "      ID: \(id)\n"
                        }
                        if let type = getToolCallType(at: index, toolCallIndex: toolCallIndex) {
                            desc += "      Type: \(type)\n"
                        }
                        if let name = getToolCallFunctionName(at: index, toolCallIndex: toolCallIndex) {
                            desc += "      Function Name: \(name)\n"
                        }
                        if let arguments = getToolCallFunctionArguments(at: index, toolCallIndex: toolCallIndex) {
                            desc += "      Function Arguments: \(arguments)\n"
                        }
                    }
                }
            }
        }
        if let usage = getUsage() {
            desc += "  Usage:\n"
            if let promptTokens = getUsagePromptTokens() { desc += "    Prompt Tokens: \(promptTokens)\n" }
            if let completionTokens = getUsageCompletionTokens() { desc += "    Completion Tokens: \(completionTokens)\n" }
            if let totalTokens = getUsageTotalTokens() { desc += "    Total Tokens: \(totalTokens)\n" }
            if let completionTokensDetails = getUsageCompletionTokensDetails() {
                desc += "    Completion Tokens Details:\n"
                if let reasoningTokens = getUsageReasoningTokens() {
                    desc += "      Reasoning Tokens: \(reasoningTokens)\n"
                }
            }
        }
        if let systemFingerprint = getSystemFingerprint() {
            desc += "  System Fingerprint: \(systemFingerprint)\n"
        }
        if let error = getError() {
            desc += "  Error:\n"
            if let message = getErrorMessage() { desc += "    Message: \(message)\n" }
            if let type = getErrorType() { desc += "    Type: \(type)\n" }
            if let param = getErrorParam() { desc += "    Param: \(param)\n" }
            if let code = getErrorCode() { desc += "    Code: \(code)\n" }
        }
        return desc
    }
    
    /// Indicates whether the response is empty.
    public var isEmpty: Bool {
        return json.isEmpty
    }
    
    /// Returns the total number of choices in the response.
    public func getChoicesCount() -> Int {
        return json[CodingKeys.choices.rawValue].array?.count ?? 0
    }

    /// Checks if the given choice index is valid.
    /// - Parameter index: The index to check.
    /// - Returns: True if the index is valid, false otherwise.
    public func isValidChoiceIndex(_ index: Int) -> Bool {
        return index >= 0 && index < getChoicesCount()
    }

    /// Returns the number of tool calls for a specific choice.
    /// - Parameter choiceIndex: The index of the choice to check.
    /// - Returns: The number of tool calls, or 0 if the choice index is invalid.
    public func getToolCallsCount(at choiceIndex: Int) -> Int {
        guard isValidChoiceIndex(choiceIndex) else { return 0 }
        return json[CodingKeys.choices.rawValue][choiceIndex]["message"][CodingKeys.toolCalls.rawValue].array?.count ?? 0
    }

    /// Checks if the given tool call index is valid for a specific choice.
    /// - Parameters:
    ///   - choiceIndex: The index of the choice.
    ///   - toolCallIndex: The index of the tool call to check.
    /// - Returns: True if both indices are valid, false otherwise.
    public func isValidToolCallIndex(choiceIndex: Int, toolCallIndex: Int) -> Bool {
        return isValidChoiceIndex(choiceIndex) && toolCallIndex >= 0 && toolCallIndex < getToolCallsCount(at: choiceIndex)
    }

    /// Returns a specific tool call for a given choice and tool call index.
    /// - Parameters:
    ///   - choiceIndex: The index of the choice.
    ///   - toolCallIndex: The index of the tool call.
    /// - Returns: The tool call information, or nil if either index is invalid.
    public func getToolCall(at choiceIndex: Int, toolCallIndex: Int) -> JSON? {
        guard isValidToolCallIndex(choiceIndex: choiceIndex, toolCallIndex: toolCallIndex) else { return nil }
        return json[CodingKeys.choices.rawValue][choiceIndex]["message"][CodingKeys.toolCalls.rawValue][toolCallIndex]
    }

    /// Returns the ID of a specific tool call.
    /// - Parameters:
    ///   - choiceIndex: The index of the choice.
    ///   - toolCallIndex: The index of the tool call.
    /// - Returns: The tool call ID, or nil if either index is invalid.
    public func getToolCallId(at choiceIndex: Int, toolCallIndex: Int) -> String? {
        return getToolCall(at: choiceIndex, toolCallIndex: toolCallIndex)?["id"].string
    }

    /// Returns the type of a specific tool call.
    /// - Parameters:
    ///   - choiceIndex: The index of the choice.
    ///   - toolCallIndex: The index of the tool call.
    /// - Returns: The tool call type, or nil if either index is invalid.
    public func getToolCallType(at choiceIndex: Int, toolCallIndex: Int) -> String? {
        return getToolCall(at: choiceIndex, toolCallIndex: toolCallIndex)?["type"].string
    }

    /// Returns the function information of a specific tool call.
    /// - Parameters:
    ///   - choiceIndex: The index of the choice.
    ///   - toolCallIndex: The index of the tool call.
    /// - Returns: The tool call function information, or nil if either index is invalid.
    public func getToolCallFunction(at choiceIndex: Int, toolCallIndex: Int) -> JSON? {
        return getToolCall(at: choiceIndex, toolCallIndex: toolCallIndex)?["function"]
    }

    /// Returns the function name of a specific tool call.
    /// - Parameters:
    ///   - choiceIndex: The index of the choice.
    ///   - toolCallIndex: The index of the tool call.
    /// - Returns: The tool call function name, or nil if either index is invalid.
    public func getToolCallFunctionName(at choiceIndex: Int, toolCallIndex: Int) -> String? {
        return getToolCallFunction(at: choiceIndex, toolCallIndex: toolCallIndex)?["name"].string
    }

    /// Returns the function arguments of a specific tool call.
    /// - Parameters:
    ///   - choiceIndex: The index of the choice.
    ///   - toolCallIndex: The index of the tool call.
    /// - Returns: The tool call function arguments, or nil if either index is invalid.
    public func getToolCallFunctionArguments(at choiceIndex: Int, toolCallIndex: Int) -> String? {
        return getToolCallFunction(at: choiceIndex, toolCallIndex: toolCallIndex)?["arguments"].string
    }

}
