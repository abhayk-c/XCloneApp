//
//  XCSRFState.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

import Foundation

/**
 * Twitter Auth API requires this.
 * See more here: https://en.wikipedia.org/wiki/Cross-site_request_forgery
 */
public struct XCSRFState {
    public let state: String
    public init() {
        let randSeed = Int.random(in: 1...13)
        var str = ""
        for _ in 0..<randSeed {
            str.append(UUID().uuidString)
        }
        self.state = str
    }
}
