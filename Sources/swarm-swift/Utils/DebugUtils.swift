import Foundation

public class DebugUtils {
    public static func printDebug(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("DEBUG: \(fileName):\(line) - \(function): \(message())")
        #endif
    }
    
    public static func printDebugJSON(_ data: Data, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            printDebug("JSON Data:\n\(jsonString)", file: file, function: function, line: line)
        } else {
            printDebug("Invalid JSON Data", file: file, function: function, line: line)
        }
        #endif
    }
    
    public static func printDebugHeaders(_ headers: [String: String], file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        printDebug("Headers:", file: file, function: function, line: line)
        for (key, value) in headers {
            if key.lowercased() == "authorization" || key.lowercased() == "api-key" {
                let maskedValue = String(value.prefix(4)) + String(repeating: "*", count: max(0, value.count - 4))
                printDebug("  \(key): \(maskedValue)", file: file, function: function, line: line)
            } else {
                printDebug("  \(key): \(value)", file: file, function: function, line: line)
            }
        }
        #endif
    }
}
