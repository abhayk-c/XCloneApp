//
//  XUserSession.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/22/25.
//

import Foundation
import Security

public struct XUserSessionContext {
    public let accessToken: String
    public let user: XUserModel
}

public typealias XSetCurrentSessionCompletionHandler = ((_ didSetSessionCredentials: Bool, _ error: XUserSessionError?) -> Void)
public typealias XGetUserSessionContextCompletionHandler = ((_ sessionContext: XUserSessionContext?,
                                                             _ error: XUserSessionError?) -> Void)

public enum XUserSessionError: Error {
    case keychainError(_ status: OSStatus)
    case refreshTokenFetchError(_ error: XAuthServiceError?)
    case getUserFetchError(_ error: XUserIdentityServiceError?)
}

/**
 * XUserSession is an object that represents the current active session (logged in user)
 * with X. Please use this class to securely get the current authenticated XUser object and
 * the current active access token which are both needed to make backend X API calls.
 * You can also use this object to establish and set a new session with new token credentials.
 * This object is a foundational object that many feature surfaces rely on, as a result you will
 * see this class in the constructor of many objects and passed to many dependencies generously
 * in the application.
 *
 * This object provides a simple Facade and takes care of the "secure storage" of session tokens/credentials
 * and refreshes the current session as needed (fetches new tokens) under the hood. As a result API's are async.
 * This class is main-thread confined. You must call the API's on the main thread, callbacks are
 * invoked on the main-thread.
 */
public class XUserSession {

    private typealias XGetAccessTokenCompletionHandler = ((_ accessToken: String?, _ error: XUserSessionError?) -> Void)
    private struct XUserSessionConstants {
        static let accessTokenKeychainId = "x.accessToken"
        static let refreshTokenKeychainId = "x.refreshToken"
        static let authStatusDefaultsKey = "userAuthenticated"
        static let sessionExpiryDefaultsKey = "sessionExpiry"
        static let sessionExpiryThreshold: TimeInterval = 60
    }

    private var accessToken: String?
    private var sessionExpiry: TimeInterval?
    private var currentUser: XUserModel?
    private let userSessionQueue = DispatchQueue(label: "com.xcloneapp.usersession.queue", qos: .userInitiated)

    private var setCurrentSessionCompletion: XSetCurrentSessionCompletionHandler?
    private var getUserSessionContextCompletion: XGetUserSessionContextCompletionHandler?

    private var authenticationService: XAuthenticationService
    private var userIdentityService: XUserIdentityService
    private var keychainTokenStore: XSecureKeychainTokenStore

    // MARK: Public Init
    public init(_ authenticationService: XAuthenticationService,
                _ userIdentityService: XUserIdentityService,
                _ tokenStore: XSecureKeychainTokenStore) {
        preconditionMainThread()
        self.authenticationService = authenticationService
        self.userIdentityService = userIdentityService
        self.keychainTokenStore = tokenStore
    }

    // MARK: Public API
    public func didAuthenticate() -> Bool {
        preconditionMainThread()
        return UserDefaults.standard.bool(forKey: XUserSessionConstants.authStatusDefaultsKey)
    }

    public func hasActiveSession() -> Bool {
        preconditionMainThread()
        guard accessToken != nil, let sessionExpiry = sessionExpiry else { return false }
        return Date().timeIntervalSince1970 < sessionExpiry - XUserSessionConstants.sessionExpiryThreshold
    }

    public func setCurrentSession(_ tokenCredentials: XTokenCredentialsModel,
                                  _ completion: @escaping XSetCurrentSessionCompletionHandler) {
        preconditionMainThread()
        if setCurrentSessionCompletion == nil {
            setCurrentSessionCompletion = completion
            userSessionQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                // First, lets set the access token in keychain
                var status = strongSelf.keychainTokenStore.upsertTokenInKeychain(tokenCredentials.accessToken,
                                                                                 XUserSessionConstants.accessTokenKeychainId)
                if status != errSecSuccess {
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.safelyCallSetCurrentSessionCompletion(false, .keychainError(status))
                    }
                    return
                }
                // Second, lets set the refresh token in keychain
                status = strongSelf.keychainTokenStore.upsertTokenInKeychain(tokenCredentials.refreshToken,
                                                                             XUserSessionConstants.refreshTokenKeychainId)
                if status != errSecSuccess {
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.safelyCallSetCurrentSessionCompletion(false, .keychainError(status))
                    }
                    return
                }
                // Write non-secure information to UserDefaults
                UserDefaults.standard.set(true, forKey: XUserSessionConstants.authStatusDefaultsKey)
                UserDefaults.standard.set(tokenCredentials.expiresAt, forKey: XUserSessionConstants.sessionExpiryDefaultsKey)
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    // Now save in memory
                    strongSelf.accessToken = tokenCredentials.accessToken
                    strongSelf.sessionExpiry = tokenCredentials.expiresAt
                    /**
                     * Clear any previous user because it would be stale.
                     * We want to derive a new User object if we get a new accessToken
                     * every time, letting the tokens be the source of truth.
                     * We don't trigger a fetch for the authenticated user, its handled
                     * "lazily" if needed. The user object itself isn't critical to the session
                     * but the access tokens are.
                     */
                    strongSelf.currentUser = nil
                    strongSelf.safelyCallSetCurrentSessionCompletion(true, nil)
                }
            }
        }
    }

    public func getUserSessionContext(_ completion: @escaping XGetUserSessionContextCompletionHandler) {
        preconditionMainThread()
        if getUserSessionContextCompletion == nil {
            getUserSessionContextCompletion = completion
            if let currentUser = currentUser {
                if let accessToken = accessToken, hasActiveSession() {
                    let sessionContext = XUserSessionContext(accessToken: accessToken, user: currentUser)
                    safelyCallGetUserSessionContextCompletion(sessionContext, nil)
                } else {
                    fetchUserAndUpdateCurrentSessionUser { [weak self] (sessionContext, error) in
                        guard let strongSelf = self else { return }
                        strongSelf.safelyCallGetUserSessionContextCompletion(sessionContext, error)
                    }
                }
            } else {
                fetchUserAndUpdateCurrentSessionUser { [weak self] (sessionContext, error) in
                    guard let strongSelf = self else { return }
                    strongSelf.safelyCallGetUserSessionContextCompletion(sessionContext, error)
                }
            }
        }
    }

    // MARK: Private Helpers
    /**
     * Fetches the current User from X's Identity endpoint and updates the current session.
     * Returns a XUserSessionContext or Error
     */
    private func fetchUserAndUpdateCurrentSessionUser(_ completion: @escaping XGetUserSessionContextCompletionHandler) {
        getAccessTokenAndRefreshSessionIfNeeded { [weak self] (accessToken, error) in
            guard let strongSelf = self else { return }
            if let accessToken = accessToken, error == nil {
                strongSelf.userIdentityService.getUserForAccessToken(accessToken) { [weak self] user, error in
                    if let user = user, error == nil {
                        // Already on the main thread
                        guard let strongSelf = self else { return }
                        strongSelf.currentUser = user
                        let sessionContext = XUserSessionContext(accessToken: accessToken, user: user)
                        completion(sessionContext, nil)
                    } else {
                        // Already on the main thread
                        completion(nil, .getUserFetchError(error))
                    }
                }
            } else {
                completion(nil, error)
            }
        }
    }

    /**
     * Retrieves the current session access token either from cache or network.
     * If the access token has expired this will get new valid tokens from X's token endpoint
     * and "reset" the current session with the new token credentials.
     * Returns the accessToken or an Error.
     */
    private func getAccessTokenAndRefreshSessionIfNeeded(_ completion: @escaping XGetAccessTokenCompletionHandler) {
        preconditionMainThread()
        if let accessToken = accessToken {
            if hasActiveSession() {
                completion(accessToken, nil)
            } else {
                userSessionQueue.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.refreshTokensAndUpdateCurrentSessionTokens(completion)
                }
            }
        } else {
            userSessionQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                let readAccessToken = strongSelf.keychainTokenStore.readTokenFromKeychain(XUserSessionConstants.accessTokenKeychainId)
                let sessionExpiry: TimeInterval = UserDefaults.standard.double(forKey: XUserSessionConstants.sessionExpiryDefaultsKey)
                if readAccessToken.status == errSecSuccess, let accessToken = readAccessToken.token {
                    if Date().timeIntervalSince1970 < sessionExpiry - XUserSessionConstants.sessionExpiryThreshold {
                        DispatchQueue.main.async { [weak self] in
                            guard let strongSelf = self else { return }
                            strongSelf.accessToken = accessToken
                            strongSelf.sessionExpiry = sessionExpiry
                            completion(accessToken, nil)
                        }
                    } else {
                        strongSelf.refreshTokensAndUpdateCurrentSessionTokens(completion)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, .keychainError(readAccessToken.status))
                    }
                }
            }
        }
    }

    /**
     * Exchanges refresh tokens for new valid access tokens and resets the current session.
     * Returns the access token or an Error.
     */
    private func refreshTokensAndUpdateCurrentSessionTokens(_ completion: @escaping XGetAccessTokenCompletionHandler) {
        // Read refresh token from keychain, we are on background thread context.
        let readRefreshToken = keychainTokenStore.readTokenFromKeychain(XUserSessionConstants.refreshTokenKeychainId)
        if let refreshToken = readRefreshToken.token, readRefreshToken.status == errSecSuccess {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                // Get new access token from refresh token
                strongSelf.authenticationService.fetchTokenCredentialsFromRefreshToken(refreshToken,
                                                                                       XAuthenticationConstants.clientID) { [weak self] (tokenCredentials, error) in
                    guard let strongSelf = self else { return }
                    // On the main thread dont dispatch back to main.
                    if error == nil, let tokenCredentials = tokenCredentials {
                        strongSelf.setCurrentSession(tokenCredentials) { [weak self] (didSetSessionCredentials, error) in
                            guard let strongSelf = self else { return }
                            // Already on the main thread so dont dispatch back to main.
                            if didSetSessionCredentials, let accessToken = strongSelf.accessToken {
                                completion(accessToken, nil)
                            } else {
                                completion(nil, error)
                            }
                        }
                    } else {
                        completion(nil, .refreshTokenFetchError(error))
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(nil, .keychainError(readRefreshToken.status))
            }
        }
    }

    private func safelyCallGetUserSessionContextCompletion(_ sessionContext: XUserSessionContext?,
                                                           _ error: XUserSessionError?) {
        if let completion = getUserSessionContextCompletion {
            self.getUserSessionContextCompletion = nil
            completion(sessionContext, error)
        }
    }

    private func safelyCallSetCurrentSessionCompletion(_ didSetSessionCredentials: Bool, _ error: XUserSessionError?) {
        if let completion = setCurrentSessionCompletion {
            self.setCurrentSessionCompletion = nil
            completion(didSetSessionCredentials, error)
        }
    }

}
