import Foundation

public class Config {
    static let shared = Config()

    private var config: [String: Any]?

    init() {
        if let path = Bundle.main.path(forResource: "config", ofType: "plist") {
            config = NSDictionary(contentsOfFile: path) as? [String: Any]
        }
        
        // print("Config initialization completed")
    }

    func value(forKey key: String) -> String? {
        return config?[key] as? String
    }

    func setValue(forKey key:String, value: String) {
        config?[key] = value
    }

    func isEmpty() -> Bool {
        return config?.isEmpty ?? true
    }
}
