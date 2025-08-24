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
    case fetchingTokenCredentials(_ authorizationCode: String, _ pkce: XPKCECodeChallenge)
    case settingTokenCredentials(_ credentials: XTokenCredentials)
    case authenticationSuccess
    case authenticationFailed(_ error: XAuthenticationError)
}

public enum XAuthenticationError: Error {
    case userAuthorizationError(_ error: Error?)
    case fetchingTokenCredentialsError(_ error: Error?)
    case settingTokenCredentialsError(_ error: Error?)
}

public protocol XAuthenticationManagerDelegate: AnyObject {
    func presentationWindowForAuthSession() -> UIWindow?
    func authenticationDidSucceed()
    func authenticationFailedWithError(_ error: XAuthenticationError)
}

public class XAuthenticationManager: NSObject, ASWebAuthenticationPresentationContextProviding {

    public weak var delegate: XAuthenticationManagerDelegate?

    private let userSession = XUserSession()
    private var authenticationState: XAuthenticationState = .none
    private let authService: XAuthenticationService
    private var authSession: ASWebAuthenticationSession?

    public init(_ delegate: XAuthenticationManagerDelegate?,
                _ authenticationService: XAuthenticationService) {
        self.delegate = delegate
        self.authService = authenticationService
    }
    
    public func authenticate() {
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
            if case .none = authenticationState {
                authenticationState = newState
                handleAuthorizingUser()
            }
        case .fetchingTokenCredentials(let authorizationCode, let pkce):
            if case .authorizingUser = authenticationState {
                authenticationState = newState
                handleFetchingTokenCredentials(authorizationCode, pkce)
            }
        case .settingTokenCredentials(let credentials):
            if case .fetchingTokenCredentials = authenticationState {
                authenticationState = newState
                handleSettingTokenCredentials(credentials)
            }
        case .authenticationSuccess:
            if case .settingTokenCredentials = authenticationState {
                authenticationState = newState
                handleAuthenticationSuccess()
            }
        case .authenticationFailed(let error):
            switch authenticationState {
            case .none, .authenticationSuccess:
                return
            default:
                authenticationState = newState
                handleAuthenticationFailure(error)
            }
        }
    }

    private func handleAuthorizingUser() {
        let pkce = XPKCECodeChallenge(.s256)
        let csrf = XCSRFState()
        var authUriBuilder = XAuthorizationURLBuilder()
        authUriBuilder.apiScopes = .readTimelineWithOfflineAccess
        authUriBuilder.codeChallenge = pkce.codeChallenge
        authUriBuilder.codeChallengeMethod = pkce.challengeMethod
        authUriBuilder.state = csrf.state
        if let authUri = authUriBuilder.buildURL() {
            authSession = ASWebAuthenticationSession(url: authUri,
                                                               callbackURLScheme: XAuthenticationConstants.redirectScheme,
                                                               completionHandler: { [weak self] (callbackURL, error) in
                                                                    if let strongSelf = self {
                                                                        strongSelf.handleAuthorizationCallback(callbackURL, error, pkce, csrf)
                                                                    }
                                                               })
            authSession?.presentationContextProvider = self
            authSession?.start()
        }
    }
    
    private func handleAuthorizationCallback(_ callbackURL: URL?,
                                             _ error: Error?,
                                             _ pkce: XPKCECodeChallenge,
                                             _ csrf: XCSRFState) {
        if let callbackURI = callbackURL, error == nil {
            if let urlComponents = URLComponents(string: callbackURI.absoluteString) {
                let stateQueryParam = urlComponents.queryItems?.first(where: { $0.name == XAuthenticationConstants.stateKey })
                let authCodeQueryParam = urlComponents.queryItems?.first(where: { $0.name == XAuthenticationConstants.codeKey })
                if let state = stateQueryParam?.value, let authCode = authCodeQueryParam?.value {
                    if state == csrf.state {
                        updateState(.fetchingTokenCredentials(authCode, pkce))
                    } else {
                        updateState(.authenticationFailed(.userAuthorizationError(nil)))
                    }
                } else {
                    updateState(.authenticationFailed(.userAuthorizationError(nil)))
                }
            } else {
                updateState(.authenticationFailed(.userAuthorizationError(nil)))
            }
        } else {
            updateState(.authenticationFailed(.userAuthorizationError(error)))
        }
    }

    private func handleFetchingTokenCredentials(_ authorizationCode: String, _ pkce: XPKCECodeChallenge) {
        authService.fetchTokenCredentialsDuringOAuth(authorizationCode,
                                                               XAuthenticationConstants.clientID,
                                                               XAuthenticationConstants.redirectURI,
                                                               pkce.codeVerifier) { [weak self] tokenCredentials, error in
            if let strongSelf = self {
                if let tokenCredentials = tokenCredentials, error == nil {
                    strongSelf.updateState(.settingTokenCredentials(tokenCredentials))
                } else {
                    strongSelf.updateState(.authenticationFailed(.fetchingTokenCredentialsError(error)))
                }
            }
        }
    }
    
    private func handleSettingTokenCredentials(_ tokenCredentials: XTokenCredentials) {
        userSession.setTokenCredentials(tokenCredentials) { (didSetCredentials: Bool, error: XUserSessionError?) in
            if didSetCredentials {
                // no op, but we do some shat
            }
        }
    }

    private func handleAuthenticationSuccess() {
        // no op
    }
    
    private func handleAuthenticationFailure(_ error: XAuthenticationError) {
        delegate?.authenticationFailedWithError(error)
    }

}
