//
//  XAuthenticationService.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/21/25.
//

import Foundation

public struct XTokenCredentials {
    public let accessToken: String
    public let refreshToken: String
}

public typealias XAuthServiceCompletionHandler = ((_ tokenCredentials: XTokenCredentials) -> Void)

public class XAuthenticationService {
    
    private var oauthCompletion: XAuthServiceCompletionHandler?
    private var refreshTokenCompletion: XAuthServiceCompletionHandler?
    
    public func fetchTokenCredentialsDuringOAuth(_ authorizationCode: String,
                                                 _ clientID: String,
                                                 _ redirectURI: String,
                                                 _ codeVerifier: String,
                                                 _ completion: @escaping XAuthServiceCompletionHandler) {
        oauthCompletion = completion
        var requestBuilder = XHTTPRequestBuilder()
        requestBuilder.httpMethod = .post
        requestBuilder.httpHeaders = [XContentTypeHTTPHeader()]
        requestBuilder.url = URL(string: XAuthenticationConstants.authTokenEndpointURI)
        requestBuilder.httpBody = [
            XAuthenticationConstants.codeKey: authorizationCode,
            XAuthenticationConstants.clientIDKey: clientID,
            XAuthenticationConstants.redirectURIKey: redirectURI,
            XAuthenticationConstants.grantTypeKey: XAuthenticationConstants.grantType,
            XAuthenticationConstants.codeVerifierKey: codeVerifier
        ]
        if let request = requestBuilder.buildRequest() {
            let task = URLSession.shared.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
                if let strongSelf = self {
                    if error == nil {
                        let decodedStr = String(data: data!, encoding: .utf8)
                        print(decodedStr)
                        if let oauthCompletion = strongSelf.oauthCompletion {
                            DispatchQueue.main.async {
                                oauthCompletion(XTokenCredentials(accessToken: "", refreshToken: ""))
                            }
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    public func fetchTokenCredentialsFromRefreshToken(_ refreshToken: String,
                                                      _ clientID: String,
                                                      _ completion: @escaping XAuthServiceCompletionHandler) {
        
    }
    
}
