//
//  XAuthenticationManager.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

import UIKit
import AuthenticationServices

private let invalidCSFError = NSError(domain: "authManager",
                                      code: 0,
                                      userInfo: [NSLocalizedDescriptionKey: "Invalid CSF State parameter during Oauth2.0 authorization"])

private let emptyResponseError = NSError(domain: "authManager",
                                         code: 0,
                                         userInfo: [NSLocalizedDescriptionKey: "Empty response from authorization server"])

private enum XAuthenticationState {
    case none
    case authorizingUser
    case fetchingTokenCredentials(_ authorizationCode: String, _ pkce: XPKCECodeChallenge)
    case settingTokenCredentials(_ credentials: XTokenCredentials)
    case authenticationSuccess
    case authenticationFailed(_ error: XAuthenticationError)
    case authenticationCancelled
}

public enum XAuthenticationError: Error {
    case userAuthError(_ error: Error?)
    case fetchingTokenCredentialsError(_ error: Error?)
    case settingTokenCredentialsError(_ error: Error?)
}

public protocol XAuthenticationManagerDelegate: AnyObject {
    func presentationWindowForAuthSession() -> UIWindow?
    func authenticationDidSucceed(_ userSession: XUserSession)
    func authenticationFailedWithError(_ error: XAuthenticationError)
    func authenticationCancelledByUser()
}

/**
 * XAuthenticationManager manages user authorization and authentication with X's backend.
 * X's authentication server is based on OAuth 2.0 PKCE standard, please use this object to
 * easily manage and drive the user authentication process.
 *
 * This object provides an easy to use Facade API, simply invoke authenticate() and let
 * the manager take care of the rest. Please set the delegate to get notifited if the
 * authentication succeeds or fails. On authentication success we will pass back the XUserSession
 * object fully configured and activated for the current "session."
 * This service object is "main-thread" confined and not thread safe.
 */
public class XAuthenticationManager: NSObject, ASWebAuthenticationPresentationContextProviding {

    public weak var delegate: XAuthenticationManagerDelegate?

    private let userSession: XUserSession
    private var authenticationState: XAuthenticationState = .none
    private let authService: XAuthenticationService
    private var authSession: ASWebAuthenticationSession?

    // MARK: Initialization
    public init(_ userSession: XUserSession,
                _ delegate: XAuthenticationManagerDelegate?,
                _ authenticationService: XAuthenticationService) {
        preconditionMainThread()
        self.userSession = userSession
        self.delegate = delegate
        self.authService = authenticationService
    }

    // MARK: Public API
    public func authenticate() {
        preconditionMainThread()
        updateState(.none) // always reset
        updateState(.authorizingUser)
    }

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return delegate?.presentationWindowForAuthSession() ?? UIWindow()
    }

    // MARK: Private Helpers
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
        case .authenticationCancelled:
            switch authenticationState {
            case .none, .authenticationSuccess:
                return
            default:
                authenticationState = newState
                handleAuthenticationCancelled()
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
                                                        }})
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
                        updateState(.authenticationFailed(.userAuthError(invalidCSFError)))
                    }
                } else {
                    updateState(.authenticationFailed(.userAuthError(emptyResponseError)))
                }
            } else {
                updateState(.authenticationFailed(.userAuthError(emptyResponseError)))
            }
        } else {
            if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                updateState(.authenticationCancelled)
            } else {
                updateState(.authenticationFailed(.userAuthError(error)))
            }
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
        userSession.setCurrentSession(tokenCredentials) { [weak self] (didSetCredentials: Bool, error: XUserSessionError?) in
            if let strongSelf = self {
                if didSetCredentials && error == nil {
                    strongSelf.updateState(.authenticationSuccess)
                } else {
                    strongSelf.updateState(.authenticationFailed(.settingTokenCredentialsError(error)))
                }
            }
        }
    }

    private func handleAuthenticationSuccess() {
        delegate?.authenticationDidSucceed(userSession)
    }

    private func handleAuthenticationFailure(_ error: XAuthenticationError) {
        delegate?.authenticationFailedWithError(error)
    }

    private func handleAuthenticationCancelled() {
        delegate?.authenticationCancelledByUser()
    }

}
