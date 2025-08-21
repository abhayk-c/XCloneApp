//
//  XAuthenticationManager.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

import UIKit
import AuthenticationServices

private enum XAuthenticationState {
    case None
    case AuthorizingUser
    case FetchingAccessAndRefreshTokens
    case AuthenticationSuccess
    case AuthenticationFailed
}

public protocol XAuthenticationManagerDelegate : AnyObject {
    func presentationWindowForAuthSession() -> UIWindow?
}

private struct XAuthenticationManagerConstants {
    static let urlScheme = "xcloneapp"
}

public class XAuthenticationManager : NSObject, ASWebAuthenticationPresentationContextProviding {
    
    public weak var delegate: XAuthenticationManagerDelegate? = nil
    
    private var authenticationState: XAuthenticationState = .None
    private var authenticationSession: ASWebAuthenticationSession? = nil
    private var csrf = XCSRFState()
    private var pkce = XPKCECodeChallenge(.plain)
    private var authorizationCode = ""
    private static let kURLScheme = "xcloneapp"
    
    public func authenticate() {
        csrf = XCSRFState()
        pkce = XPKCECodeChallenge(.s256)
        authorizationCode = ""
        updateState(.None) //always reset
        updateState(.AuthorizingUser)
    }
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return delegate?.presentationWindowForAuthSession() ?? UIWindow()
    }
    
    private func updateState(_ newState: XAuthenticationState) {
        switch newState {
        case .None:
            authenticationState = newState
        case .AuthorizingUser:
            if authenticationState == .None {
                authenticationState = newState
                handleAuthorizingUser()
            }
        case .FetchingAccessAndRefreshTokens:
            if authenticationState == .AuthorizingUser {
                authenticationState = newState
                handleFetchingAccessAndRefreshTokens()
            }
        case .AuthenticationSuccess:
            if authenticationState == .FetchingAccessAndRefreshTokens {
                authenticationState = newState
                handleAuthenticationSuccessOrFailure()
            }
        case .AuthenticationFailed:
            if authenticationState != .None && authenticationState != .AuthenticationSuccess {
                authenticationState = newState
                handleAuthenticationSuccessOrFailure()
            }
        }
    }
    
    private func handleAuthorizingUser() {
        var authUriBuilder = XAuthorizationURLBuilder()
        authUriBuilder.apiScopes = .readTimelineWithOfflineAccess
        authUriBuilder.codeChallenge = pkce.codeChallenge
        authUriBuilder.codeChallengeMethod = pkce.challengeMethod
        authUriBuilder.state = csrf.state
        if let authUri = authUriBuilder.buildURL() {
            authenticationSession = ASWebAuthenticationSession(url: authUri,
                                                               callbackURLScheme: XAuthenticationManagerConstants.urlScheme,
                                                               completionHandler: { [weak self] (callbackURL, error) in
                if let strongSelf = self {
                    if let callbackURI = callbackURL, error == nil {
                        if let urlComponents = URLComponents(string: callbackURI.absoluteString) {
                            let stateQueryParam = urlComponents.queryItems?.first(where: { $0.name == "state" })
                            let authCodeQueryParam = urlComponents.queryItems?.first(where: { $0.name == "code" })
                            if let state = stateQueryParam?.value, let authCode = authCodeQueryParam?.value {
                                if state == strongSelf.csrf.state {
                                    strongSelf.authorizationCode = authCode
                                    strongSelf.updateState(.FetchingAccessAndRefreshTokens)
                                }
                            }
                        }
                    } else {
                        
                    }
                }
            })
            authenticationSession?.presentationContextProvider = self
            authenticationSession?.start()
        }
    }
    
    private func handleFetchingAccessAndRefreshTokens() {
        print("Beginning Access Token fetch")
        print("Authorization Code: \(authorizationCode)")
    }
    
    private func handleAuthenticationSuccessOrFailure() {
        
    }
    
}
