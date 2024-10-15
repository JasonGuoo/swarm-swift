import Foundation

public class Config {
    private var config: [String: String] = [:]

    public init() {}

    public func value(forKey key: String) -> String? {
        return config[key]
    }

    public func setValue(forKey key: String, value: String) {
        config[key] = value
    }

    public func isEmpty() -> Bool {
        return config.isEmpty
    }

    public var description: String {
        return config.map { key, value in "\(key)=\(value)" }.joined(separator: "\n")
    }
}
