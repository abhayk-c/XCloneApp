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

public class XAuthenticationService {
    
    private var oauthCompletion: XAuthServiceCompletionHandler?
    private var refreshTokenCompletion: XAuthServiceCompletionHandler?
    
    public func fetchTokenCredentialsDuringOAuth(_ authorizationCode: String,
                                                 _ clientID: String,
                                                 _ redirectURI: String,
                                                 _ codeVerifier: String,
                                                 _ completion: @escaping XAuthServiceCompletionHandler) {
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
                let task = URLSession.shared.dataTask(with: request) { [weak self] (data: Data?,
                                                                                    response: URLResponse?,
                                                                                    error: Error?) in
                    if let strongSelf = self {
                        strongSelf.handleAuthTokenEndpointResponse(data, error, strongSelf.oauthCompletion)
                        strongSelf.oauthCompletion = nil
                    }
                }
                task.resume()
            }
        }
    }
    
    public func fetchTokenCredentialsFromRefreshToken(_ refreshToken: String,
                                                      _ clientID: String,
                                                      _ completion: @escaping XAuthServiceCompletionHandler) {
        if refreshTokenCompletion == nil {
            refreshTokenCompletion = completion
            var requestBuilder = XHTTPRequestBuilder()
            requestBuilder.httpMethod = .post
            requestBuilder.httpHeaders = [XContentTypeHTTPHeader()]
            requestBuilder.url = URL(string: XAuthenticationConstants.authTokenEndpointURI)
            requestBuilder.httpBody = [
                XAuthenticationConstants.refreshTokenKey: refreshToken,
                XAuthenticationConstants.clientIDKey: clientID,
                XAuthenticationConstants.grantTypeKey: XAuthenticationConstants.grantTypeRefreshToken,
            ]
            if let request = requestBuilder.buildRequest() {
                let task = URLSession.shared.dataTask(with: request) { [weak self] (data: Data?,
                                                                                    response: URLResponse?,
                                                                                    error: Error?) in
                    if let strongSelf = self {
                        strongSelf.handleAuthTokenEndpointResponse(data, error, strongSelf.refreshTokenCompletion)
                        strongSelf.refreshTokenCompletion = nil
                    }
                }
                task.resume()
            }
        }
    }
    
    private func handleAuthTokenEndpointResponse(_ data: Data?,
                                                 _ error: Error?,
                                                 _ callbackCompletion: XAuthServiceCompletionHandler?) {
        if let error = error {
            DispatchQueue.main.async {
                callbackCompletion?(nil, .httpError(error: error))
            }
        } else {
            if let data = data {
                do {
                    let credentials = try JSONDecoder().decode(XTokenCredentials.self, from: data)
                    DispatchQueue.main.async {
                        callbackCompletion?(credentials, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        callbackCompletion?(nil, .jsonDecodingError(error: error))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    callbackCompletion?(nil, .emptyResponseError)
                }
            }
        }
    }
    
}
