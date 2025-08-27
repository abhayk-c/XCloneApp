//
//  XUserSession.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/22/25.
//

import Foundation
import Security

private struct XUserSessionConstants {
    static let accessTokenKeychainId = "x.accessToken"
    static let refreshTokenKeychainId = "x.refreshToken"
    static let authStatusDefaultsKey = "userAuthenticated"
    static let sessionExpiryDefaultsKey = "sessionExpiry"
    static let sessionExpiryThreshold: TimeInterval = 60
}

public typealias XSetCurrentSessionCompletionHandler = ((_ didSetSessionCredentials: Bool, _ error: XUserSessionError?) -> Void)
public typealias XGetAccessTokenCompletionHandler = ((_ accessToken: String?, _ error: XUserSessionError?) -> Void)
public typealias XGetUserCompletionHandler = ((_ user: XUser?, _ error: XUserSessionError?) -> Void)
public typealias XGetUserAndAccessTokenCompletionHandler = ((_ user: XUser?,
                                                             _ accessToken: String?,
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
 * This object is a foundational object that many feature surfacesrely on, as a result you will
 * see this class in the constructor of many objects and passed to many dependencies generously
 * in the application.
 *
 * This object provides a simple Facade and takes care of the "secure storage" of session tokens/credentials
 * and refreshes the current session as needed (fetches new tokens). As a result API's are async.
 * This class is main-thread confined. You must call the API's on the main thread, callbacks are on the main-thread.
 */
public class XUserSession {

    private var accessToken: String?
    private var sessionExpiry: TimeInterval?
    private var currentUser: XUser?
    private let userSessionQueue = DispatchQueue(label: "com.xcloneapp.usersession.queue", qos: .userInteractive)

    private var setCurrentSessionCompletion: XSetCurrentSessionCompletionHandler?
    private var getAccessTokenCompletion: XGetAccessTokenCompletionHandler?
    private var getUserCompletion: XGetUserCompletionHandler?
    private var getUserAndAccessTokenCompletion: XGetUserAndAccessTokenCompletionHandler?

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

    public func setCurrentSession(_ tokenCredentials: XTokenCredentials,
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
                    strongSelf.safelyCallSetCurrentSessionCompletion(true, nil)
                }
            }
        }
    }

    public func getUserAndAccessToken(_ completion: @escaping XGetUserAndAccessTokenCompletionHandler) {
        preconditionMainThread()
        if getUserAndAccessTokenCompletion == nil {
            getUserAndAccessTokenCompletion = completion
            getAccessToken { [weak self] (accessToken, error) in
                guard let strongSelf = self else { return }
                if let accessToken = accessToken, error == nil {
                    strongSelf.getUser { [weak self] (user, error) in
                        guard let strongSelf = self else { return }
                        if let user = user, error == nil {
                            strongSelf.safelyCallGetUserAndAccessTokenCompletion(user, accessToken, nil)
                        } else {
                            strongSelf.safelyCallGetUserAndAccessTokenCompletion(nil, nil, error)
                        }
                    }
                } else {
                    strongSelf.safelyCallGetUserAndAccessTokenCompletion(nil, nil, error)
                }
            }
        }
    }

    public func getUser(_ completion: @escaping XGetUserCompletionHandler) {
        preconditionMainThread()
        if getUserCompletion == nil {
            getUserCompletion = completion
            if let currentUser = currentUser {
                if hasActiveSession() {
                    safelyCallGetUserCompletion(currentUser, nil)
                } else {
                    getAccessTokenAndFetchUser()
                }
            } else {
                getAccessTokenAndFetchUser()
            }
        }
    }

    public func getAccessToken(_ completion: @escaping XGetAccessTokenCompletionHandler) {
        preconditionMainThread()
        if getAccessTokenCompletion == nil {
            getAccessTokenCompletion = completion
            if let accessToken = accessToken {
                if hasActiveSession() {
                    safelyCallGetAccessTokenCompletion(accessToken, nil)
                } else {
                    userSessionQueue.async { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.refreshSessionAndUpdateAccessToken()
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
                                strongSelf.safelyCallGetAccessTokenCompletion(accessToken, nil)
                            }
                        } else {
                            strongSelf.refreshSessionAndUpdateAccessToken()
                        }
                    } else {
                        DispatchQueue.main.async { [weak self] in
                            guard let strongSelf = self else { return }
                            strongSelf.safelyCallGetAccessTokenCompletion(nil, .keychainError(readAccessToken.status))
                        }
                    }
                }
            }
        }
    }

    // MARK: Private Helpers
    private func getAccessTokenAndFetchUser() {
        getAccessToken { [weak self] (accessToken, error) in
            guard let strongSelf = self else { return }
            if let accessToken = accessToken, error == nil {
                strongSelf.userIdentityService.getUserForAccessToken(accessToken) { user, error in
                    if let user = user, error == nil {
                        // Already on the main thread
                        guard let strongSelf = self else { return }
                        strongSelf.currentUser = user
                        strongSelf.safelyCallGetUserCompletion(user, nil)
                    } else {
                        // Already on the main thread
                        guard let strongSelf = self else { return }
                        strongSelf.safelyCallGetUserCompletion(user, .getUserFetchError(error))
                    }
                }
            } else {
                strongSelf.safelyCallGetUserCompletion(nil, error)
            }
        }
    }

    private func refreshSessionAndUpdateAccessToken() {
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
                                strongSelf.safelyCallGetAccessTokenCompletion(accessToken, nil)
                            } else {
                                strongSelf.safelyCallGetAccessTokenCompletion(nil, error)
                            }
                        }
                    } else {
                        strongSelf.safelyCallGetAccessTokenCompletion(nil, .refreshTokenFetchError(error))
                    }
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.safelyCallGetAccessTokenCompletion(nil, .keychainError(readRefreshToken.status))
            }
        }
    }

    private func safelyCallGetUserCompletion(_ user: XUser?, _ error: XUserSessionError?) {
        if let completion = getUserCompletion {
            self.getUserCompletion = nil
            completion(user, error)
        }
    }

    private func safelyCallGetUserAndAccessTokenCompletion(_ user: XUser?,
                                                           _ accessToken: String?,
                                                           _ error: XUserSessionError?) {
        if let completion = getUserAndAccessTokenCompletion {
            self.getUserAndAccessTokenCompletion = nil
            completion(user, accessToken, error)
        }
    }

    private func safelyCallSetCurrentSessionCompletion(_ didSetSessionCredentials: Bool, _ error: XUserSessionError?) {
        if let completion = setCurrentSessionCompletion {
            self.setCurrentSessionCompletion = nil
            completion(didSetSessionCredentials, error)
        }
    }

    private func safelyCallGetAccessTokenCompletion(_ accessToken: String?, _ error: XUserSessionError?) {
        if let completion = getAccessTokenCompletion {
            self.getAccessTokenCompletion = nil
            completion(accessToken, error)
        }
    }

}
