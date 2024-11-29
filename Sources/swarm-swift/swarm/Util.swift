import Foundation
import SwiftyJSON

// Date formatter
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

func debugPrint(debug: Bool, _ args: Any...) {
    guard debug else { return }
    let timestamp = dateFormatter.string(from: Date())
    let message = args.map { String(describing: $0) }.joined(separator: " ")
    print("\u{001B}[97m[\u{001B}[90m\(timestamp)\u{001B}[97m]\u{001B}[90m \(message)\u{001B}[0m")
}


/// Generates the dynamic function name for Objective-C method calling.
///
/// - Parameters:
///   - functionName: The original function name.
/// - Returns: The generated dynamic function name.
///
/// This function constructs the Objective-C style selector name by appending
/// parameter names to the function name, separated by "With" and ":".
///
func generateDynamicFunctionName(functionName: String) -> String {
    let baseNameComponents = functionName.split(separator: "_")
    let baseName = baseNameComponents.joined(separator: "_")
//    return "\(baseName)WithArgs:"
    return "\(baseName):"
}

/// Calls a function on an Agent object based on the provided function definition and arguments.
///
/// - Parameters:
///   - agent: The Agent object on which to call the function.
///   - functionName: The name of the function to be called.
///   - arguments: A JSON string of arguments to pass to the function.
/// - Returns: The result of the function call.
/// - Throws: FunctionCallError if the function is not found or if required parameters are missing.
///
/// This function demonstrates how to dynamically call a method on a Swift object:
/// 1. The class must inherit from NSObject.
/// 2. The method must be marked with @objc.

func callFunction(agent: Agent, functionName: String, arguments: String) throws -> Any {
    // 1. Find the corresponding function in the agent's functions
    guard let functions = agent.functions,
          let tool = functions.arrayValue.first(where: { $0["function"]["name"].stringValue == functionName }) else {
        throw FunctionCallError.functionNotFound(functionName)
    }
    
    // 2. Validate arguments
    let argsJSON = JSON(parseJSON: arguments)
    for requiredParam in tool["function"]["parameters"]["required"].arrayValue {
        guard argsJSON[requiredParam.stringValue] != JSON.null else {
            throw FunctionCallError.missingRequiredParameter(requiredParam.stringValue)
        }
    }
    
    // Generate the dynamic function name
    let dynamicFunctionName = generateDynamicFunctionName(functionName: functionName)
    
    // Use the generated dynamic function name to create the selector
    let selector = NSSelectorFromString(dynamicFunctionName)
    
    // Print the class name of the agent
    print("Agent class: \(type(of: agent))")
    // Print all callable function names of the agent instance
    let methods = class_copyMethodList(type(of: agent), UnsafeMutablePointer<UInt32>.allocate(capacity: 1))
    defer { free(methods) }
    
    print("Callable functions for agent:")
    var methodPtr = methods
    while let method = methodPtr?.pointee {
        let selector = method_getName(method)
        let methodName = NSStringFromSelector(selector)
        print("- \(methodName)")
        methodPtr = methodPtr?.successor()
    }
    
    guard agent.responds(to: selector) else {
        throw FunctionCallError.functionNotFound(functionName)
    }
    
    guard let result = agent.perform(selector, with: argsJSON.dictionaryObject)?.takeUnretainedValue() else {
        throw FunctionCallError.functionCallFailed(functionName)
    }
    
    // Return the result directly if it's a String or Agent
    if result is String || result is Agent {
        return result
    }
    
    // For backward compatibility, try to handle Data type
    if let jsonData = result as? Data {
        do {
            let swarmResult = try JSONDecoder().decode(SwarmResult.self, from: jsonData)
            return swarmResult
        } catch {
            throw FunctionCallError.deserializationFailed(functionName, error)
        }
    }
    
    throw FunctionCallError.unexpectedReturnType(functionName, String(describing: type(of: result)))
}

/// Calls a function on an Agent object based on the provided function definition and arguments.
///
/// - Parameters:
///   - agent: The Agent object on which to call the function.
///   - functionName: The name of the function to be called.
///   - arguments: A JSON string of arguments to pass to the function.
/// - Returns: The result of the function call.
/// - Throws: FunctionCallError if the function is not found or if required parameters are missing.
///
/// This function demonstrates how to dynamically call a method on a Swift object:
/// 1. The class must inherit from NSObject.
/// 2. The method must be marked with @objc.

func callFunctionDirectly(agent: Agent, functionName: String, arguments: String) throws -> Any {
    let dynamicFuncName = generateDynamicFunctionName(functionName: functionName)
    let selector = NSSelectorFromString(dynamicFuncName)
    
    guard agent.responds(to: selector) else {
        throw FunctionCallError.functionNotFound(functionName)
    }
    
    guard let result = agent.perform(selector, with: JSON(arguments).dictionaryObject)?.takeUnretainedValue() else {
        throw FunctionCallError.functionCallFailed(functionName)
    }
    
    if let jsonData = result as? Data {
        do {
            let swarmResult = try JSONDecoder().decode(SwarmResult.self, from: jsonData)
            return swarmResult
        } catch {
            throw FunctionCallError.deserializationFailed(functionName, error)
        }
    } else {
        throw FunctionCallError.unexpectedReturnType(functionName, String(describing: type(of: result)))
    }
}

/// Enum representing errors that can occur during function calls.
enum FunctionCallError: Error, Equatable {
    /// Indicates that the specified function was not found on the agent.
    case functionNotFound(String)
    /// Indicates that a required parameter is missing from the arguments.
    case missingRequiredParameter(String)
    /// Indicates that the function call failed.
    case functionCallFailed(String)
    /// Indicates that the function returned an unexpected type.
    case unexpectedReturnType(String, String)
    /// Indicates that deserialization failed.
    case deserializationFailed(String, Error)
    
    static func == (lhs: FunctionCallError, rhs: FunctionCallError) -> Bool {
        switch (lhs, rhs) {
        case (.functionNotFound(let a), .functionNotFound(let b)):
            return a == b
        case (.missingRequiredParameter(let a), .missingRequiredParameter(let b)):
            return a == b
        case (.functionCallFailed(let a), .functionCallFailed(let b)):
            return a == b
        case (.unexpectedReturnType(let a1, let a2), .unexpectedReturnType(let b1, let b2)):
            return a1 == b1 && a2 == b2
        case (.deserializationFailed(let a, _), .deserializationFailed(let b, _)):
            return a == b
        default:
            return false
        }
    }
}
