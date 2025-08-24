//
//  XAuthenticationService.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/21/25.
//

import Foundation

public enum XAuthServiceError: Error {
    case emptyResponseError
    case jsonDecodingError(error: Error)
    case httpError(error: Error)
}

public typealias XAuthServiceCompletionHandler = ((_ tokenCredentials: XTokenCredentials?, _ error: XAuthServiceError?) -> Void)

/**
 * XAuthenticationService helps authorize and authenticate a user with X's
 * backend OAuth 2.0 authorization server. You can use this service to fetch scoped API
 * access tokens and refresh tokens. In most cases you should not use this object directly.
 * Consider using AuthenticationManager and UserSession which provide a cleaner Facade
 * for user authentication and managing/refreshing the active session.
 *
 * This service object is "main-thread" confined and not thread safe.
 * The network requests are executed on background threads but the completion
 * callback's are called on the main-thread, and API's are expected to be called on main.
 */
public class XAuthenticationService {

    private var oauthCompletion: XAuthServiceCompletionHandler?
    private var refreshTokenCompletion: XAuthServiceCompletionHandler?

    // MARK: Public API
    public func fetchTokenCredentialsDuringOAuth(_ authorizationCode: String,
                                                 _ clientID: String,
                                                 _ redirectURI: String,
                                                 _ codeVerifier: String,
                                                 _ completion: @escaping XAuthServiceCompletionHandler) {
        preconditionMainThread()
        if oauthCompletion == nil {
            oauthCompletion = completion
            var requestBuilder = XHTTPRequestBuilder()
            requestBuilder.httpMethod = .post
            requestBuilder.httpHeaders = [XContentTypeHTTPHeader()]
            requestBuilder.url = URL(string: XAuthenticationConstants.authTokenEndpointURI)
            requestBuilder.httpBody = [
                XAuthenticationConstants.codeKey: authorizationCode,
                XAuthenticationConstants.clientIDKey: clientID,
                XAuthenticationConstants.redirectURIKey: redirectURI,
                XAuthenticationConstants.grantTypeKey: XAuthenticationConstants.grantTypeAuthCode,
                XAuthenticationConstants.codeVerifierKey: codeVerifier
            ]
            if let request = requestBuilder.buildRequest() {
                let task = URLSession.shared.dataTask(with: request) { (data: Data?, _: URLResponse?, error: Error?) in
                    DispatchQueue.main.async { [weak self] in
                        if let strongSelf = self {
                            if let oauthCompletion = strongSelf.oauthCompletion {
                                strongSelf.oauthCompletion = nil
                                strongSelf.handleAuthTokenEndpointResponse(data, error, oauthCompletion)
                            }
                        }
                    }
                }
                task.resume()
            }
        }
    }

    public func fetchTokenCredentialsFromRefreshToken(_ refreshToken: String,
                                                      _ clientID: String,
                                                      _ completion: @escaping XAuthServiceCompletionHandler) {
        preconditionMainThread()
        if refreshTokenCompletion == nil {
            refreshTokenCompletion = completion
            var requestBuilder = XHTTPRequestBuilder()
            requestBuilder.httpMethod = .post
            requestBuilder.httpHeaders = [XContentTypeHTTPHeader()]
            requestBuilder.url = URL(string: XAuthenticationConstants.authTokenEndpointURI)
            requestBuilder.httpBody = [
                XAuthenticationConstants.refreshTokenKey: refreshToken,
                XAuthenticationConstants.clientIDKey: clientID,
                XAuthenticationConstants.grantTypeKey: XAuthenticationConstants.grantTypeRefreshToken
            ]
            if let request = requestBuilder.buildRequest() {
                let task = URLSession.shared.dataTask(with: request) { (data: Data?, _: URLResponse?, error: Error?) in
                    DispatchQueue.main.async { [weak self] in
                        if let strongSelf = self {
                            if let refreshTokenCompletion = strongSelf.refreshTokenCompletion {
                                strongSelf.refreshTokenCompletion = nil
                                strongSelf.handleAuthTokenEndpointResponse(data, error, refreshTokenCompletion)
                            }
                        }
                    }
                }
                task.resume()
            }
        }
    }

    // MARK: Private Helpers
    private func handleAuthTokenEndpointResponse(_ data: Data?,
                                                 _ error: Error?,
                                                 _ callbackCompletion: XAuthServiceCompletionHandler?) {
        if let error = error {
            callbackCompletion?(nil, .httpError(error: error))
        } else {
            if let data = data {
                do {
                    let credentials = try JSONDecoder().decode(XTokenCredentials.self, from: data)
                    callbackCompletion?(credentials, nil)
                } catch {
                    callbackCompletion?(nil, .jsonDecodingError(error: error))
                }
            } else {
                callbackCompletion?(nil, .emptyResponseError)
            }
        }
    }

}
