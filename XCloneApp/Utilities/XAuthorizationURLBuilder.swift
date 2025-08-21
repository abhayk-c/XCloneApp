//
//  XAuthorizationURLBuilder.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

import Foundation

private struct XAuthURLConstants {
    static let authorizationURI = "https://x.com/i/oauth2/authorize"
    static let redirectURI = "xcloneapp://"
    static let clientID = "WlNIR1ZoUWE3OTh3NElJMWM3Q2o6MTpjaQ"
    static let responseTypeValue = "code"
    
    static let responseTypeKey = "response_type"
    static let clientIDKey = "client_id"
    static let redirectURIKey = "redirect_uri"
    static let stateKey = "state"
    static let codeChallengeKey = "code_challenge"
    static let codeChallengeMethodKey = "code_challenge_method"
    static let apiScopesKey = "scope"
}

public struct XAuthorizationURLBuilder {
    
    public var apiScopes: XAPIScopes
    public var state: String
    public var codeChallenge: String
    public var codeChallengeMethod: XPKCECodeChallengeMethod
    
    public init() {
        self.apiScopes = []
        self.state = ""
        self.codeChallenge = ""
        self.codeChallengeMethod = .plain
    }
    
    public func buildURL() -> URL? {
        var urlComponents = URLComponents(string: XAuthURLConstants.authorizationURI)
        var urlQueryItems: [URLQueryItem] = []
        urlQueryItems.append(URLQueryItem(name: XAuthURLConstants.responseTypeKey, value: XAuthURLConstants.responseTypeValue))
        urlQueryItems.append(URLQueryItem(name: XAuthURLConstants.clientIDKey, value: XAuthURLConstants.clientID))
        urlQueryItems.append(URLQueryItem(name: XAuthURLConstants.redirectURIKey, value: XAuthURLConstants.redirectURI))
        urlQueryItems.append(URLQueryItem(name: XAuthURLConstants.stateKey, value: state))
        urlQueryItems.append(URLQueryItem(name: XAuthURLConstants.codeChallengeKey, value: codeChallenge))
        urlQueryItems.append(URLQueryItem(name: XAuthURLConstants.codeChallengeMethodKey, value: codeChallengeMethod.rawValue))
        urlQueryItems.append(URLQueryItem(name: XAuthURLConstants.apiScopesKey, value: apiScopes.toString()))
        urlComponents?.queryItems = urlQueryItems
        return urlComponents?.url
    }
    
}
