//
//  XHTTPParams.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/21/25.
//

/**
 * Protocol's and pre-canned definitions for the HTTP Headers
 * that the X API requires.
 */
public protocol XHTTPHeader {
    var headerParams: [String: String] { get }
}

public struct XAuthorizationHTTPHeader: XHTTPHeader {
    public private(set) var headerParams: [String: String]
    public init(_ token: String) {
        let bearerTokenStr = "Bearer \(token)"
        headerParams = ["Authorization": bearerTokenStr]
    }
}

public struct XContentTypeHTTPHeader: XHTTPHeader {
    public private(set) var headerParams: [String: String]
    public init() {
        headerParams = ["Content-Type": "application/x-www-form-urlencoded"]
    }
}
