//
//  XAuthenticationManager.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

import UIKit
import AuthenticationServices

private enum XAuthenticationState {
    case none
    case authorizingUser
    case fetchingAccessAndRefreshTokens
    case authenticationSuccess
    case authenticationFailed
}

public protocol XAuthenticationManagerDelegate: AnyObject {
    func presentationWindowForAuthSession() -> UIWindow?
}

private struct XAuthenticationManagerConstants {
    static let urlScheme = "xcloneapp"
}

public class XAuthenticationManager: NSObject, ASWebAuthenticationPresentationContextProviding {

    public weak var delegate: XAuthenticationManagerDelegate?

    private let authenticationService: XAuthenticationService
    private var authenticationState: XAuthenticationState = .none
    private var authenticationSession: ASWebAuthenticationSession?
    private var csrf = XCSRFState()
    private var pkce = XPKCECodeChallenge(.plain)
    private var authorizationCode = ""

    public init(_ delegate: XAuthenticationManagerDelegate?,
                _ authenticationService: XAuthenticationService)
    {
        self.delegate = delegate
        self.authenticationService = authenticationService
    }
    
    public func authenticate() {
        csrf = XCSRFState()
        pkce = XPKCECodeChallenge(.s256)
        authorizationCode = ""
        updateState(.none) // always reset
        updateState(.authorizingUser)
    }

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return delegate?.presentationWindowForAuthSession() ?? UIWindow()
    }

    private func updateState(_ newState: XAuthenticationState) {
        switch newState {
        case .none:
            authenticationState = newState
        case .authorizingUser:
            if authenticationState == .none {
                authenticationState = newState
                handleAuthorizingUser()
            }
        case .fetchingAccessAndRefreshTokens:
            if authenticationState == .authorizingUser {
                authenticationState = newState
                handleFetchingAccessAndRefreshTokens()
            }
        case .authenticationSuccess:
            if authenticationState == .fetchingAccessAndRefreshTokens {
                authenticationState = newState
                handleAuthenticationSuccessOrFailure()
            }
        case .authenticationFailed:
            if authenticationState != .none && authenticationState != .authenticationSuccess {
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
                                                                            let stateQueryParam = urlComponents.queryItems?.first(where: { $0.name == XAuthenticationConstants.stateKey })
                                                                            let authCodeQueryParam = urlComponents.queryItems?.first(where: { $0.name == XAuthenticationConstants.codeKey })
                                                                            if let state = stateQueryParam?.value, let authCode = authCodeQueryParam?.value {
                                                                                if state == strongSelf.csrf.state {
                                                                                    strongSelf.authorizationCode = authCode
                                                                                    strongSelf.updateState(.fetchingAccessAndRefreshTokens)
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
        authenticationService.fetchTokenCredentialsDuringOAuth(authorizationCode,
                                                               XAuthenticationConstants.clientID,
                                                               XAuthenticationConstants.redirectURI,
                                                               pkce.codeVerifier) { tokenCredentials in
            print("AuthManager: Access Token fetched")
        }
    }

    private func handleAuthenticationSuccessOrFailure() {

    }

}
