//
//  XAuthorizationURLBuilder.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

import Foundation

/**
 * X's OAuth browser URI construction is quite complicated and cumbersome.
 * Please use this builder struct to help configure and build X's OAuth2.0
 * authorization URI that we open in the browser.
 */
public struct XAuthorizationURLBuilder {

    public var apiScopes: XAPIScopes = []
    public var state: String = ""
    public var codeChallenge: String = ""
    public var codeChallengeMethod: XPKCECodeChallengeMethod = .plain

    public func buildURL() -> URL? {
        var urlComponents = URLComponents(string: XAuthenticationConstants.authorizationEndpointURI)
        var urlQueryItems: [URLQueryItem] = []
        urlQueryItems.append(URLQueryItem(name: XAuthenticationConstants.responseTypeKey, value: XAuthenticationConstants.responseType))
        urlQueryItems.append(URLQueryItem(name: XAuthenticationConstants.clientIDKey, value: XAuthenticationConstants.clientID))
        urlQueryItems.append(URLQueryItem(name: XAuthenticationConstants.redirectURIKey, value: XAuthenticationConstants.redirectURI))
        urlQueryItems.append(URLQueryItem(name: XAuthenticationConstants.stateKey, value: state))
        urlQueryItems.append(URLQueryItem(name: XAuthenticationConstants.codeChallengeKey, value: codeChallenge))
        urlQueryItems.append(URLQueryItem(name: XAuthenticationConstants.codeChallengeMethodKey, value: codeChallengeMethod.rawValue))
        urlQueryItems.append(URLQueryItem(name: XAuthenticationConstants.apiScopesKey, value: apiScopes.toString()))
        urlComponents?.queryItems = urlQueryItems
        return urlComponents?.url
    }

}
