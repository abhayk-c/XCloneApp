//
//  Data+Base64URL.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/22/25.
//

import Foundation

public extension Data {
    
    func base64URLEncodedString() -> String {
        var base64URLEncodedString = base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        while base64URLEncodedString.last == "=" { base64URLEncodedString.removeLast() }
        return base64URLEncodedString
    }
    
}
