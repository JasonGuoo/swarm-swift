//
//  LLMMessage.swift
//  
//
//  Created by Jingyuan Guo on 2024/10/21.
//

import Foundation
import SwiftyJSON

public class Message: MessageBase {
    
    public func role() ->String{
        return getString(key: "role")
    }
    
    public func content() ->String {
        return getString(key: "content")
    }
    
    public func withRole(role: String) -> Message{
        setString(forKey: "role", value: role)
        return self
    }
    
    public func withContent(content: String) -> Message{
        setString(forKey: "content", value: content)
        return self
    }
    
}

