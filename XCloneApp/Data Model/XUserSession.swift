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

public typealias XSetTokenCredentialsCompletionHandler = ((_ didSetCredentials: Bool, _ error: XUserSessionError?) -> Void)
public typealias XGetAccessTokenCompletionHandler = ((_ accessToken: String?, _ error: XUserSessionError?) -> Void)

public enum XUserSessionError: Error {
    case keychainError(_ status: OSStatus)
    case refreshTokenFetchError(_ error: XAuthServiceError?)
}

/**
 * XUserSession is an object that represents the current active session (logged in user)
 * with X. Please use this class to securely get the current access token to make backend X API calls.
 * Please also use this API to get information on the current active session and "update" the current
 * session with new credentials. This object is a foundational object that many feature surfaces
 * rely on, as a result you will see this class in the constructor of many objects and passed to many
 * dependencies generously in the application.
 *
 * This object provides a simple Facade and takes care of the "secure storage" of session tokens/credentials
 * and refreshes the current session as needed (fetches new tokens). As a result API's are async.
 * This class is main-thread confined. You must call the API's on the main thread, callbacks are on the main-thread.
 */
public class XUserSession {

    private var accessToken: String?
    private var sessionExpiry: TimeInterval?
    private let userSessionQueue = DispatchQueue(label: "com.xcloneapp.usersession.queue", qos: .userInteractive)
    private var setTokenCredentialsCompletion: XSetTokenCredentialsCompletionHandler?
    private var getAccessTokenCompletion: XGetAccessTokenCompletionHandler?
    private var authenticationService: XAuthenticationService
    private var keychainTokenStore: XSecureKeychainTokenStore

    // MARK: Public Init
    public init(_ authenticationService: XAuthenticationService,
                _ tokenStore: XSecureKeychainTokenStore) {
        preconditionMainThread()
        self.authenticationService = authenticationService
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

    public func setTokenCredentials(_ tokenCredentials: XTokenCredentials,
                                    _ completion: @escaping XSetTokenCredentialsCompletionHandler) {
        preconditionMainThread()
        if setTokenCredentialsCompletion == nil {
            setTokenCredentialsCompletion = completion
            userSessionQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                // First, lets set the access token in keychain
                var status = strongSelf.keychainTokenStore.upsertTokenInKeychain(tokenCredentials.accessToken,
                                                                                 XUserSessionConstants.accessTokenKeychainId)
                if status != errSecSuccess {
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.safelyCallSetTokenCredentialsCompletion(false, .keychainError(status))
                    }
                    return
                }
                // Second, lets set the refresh token in keychain
                status = strongSelf.keychainTokenStore.upsertTokenInKeychain(tokenCredentials.refreshToken,
                                                                             XUserSessionConstants.refreshTokenKeychainId)
                if status != errSecSuccess {
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        strongSelf.safelyCallSetTokenCredentialsCompletion(false, .keychainError(status))
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
                    strongSelf.safelyCallSetTokenCredentialsCompletion(true, nil)
                }
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
    private func safelyCallSetTokenCredentialsCompletion(_ didSetCredentials: Bool, _ error: XUserSessionError?) {
        if let completion = setTokenCredentialsCompletion {
            self.setTokenCredentialsCompletion = nil
            completion(didSetCredentials, error)
        }
    }

    private func safelyCallGetAccessTokenCompletion(_ accessToken: String?, _ error: XUserSessionError?) {
        if let completion = getAccessTokenCompletion {
            self.getAccessTokenCompletion = nil
            completion(accessToken, error)
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
                        strongSelf.setTokenCredentials(tokenCredentials) { [weak self] (didSetCredentials, error) in
                            guard let strongSelf = self else { return }
                            // Already on the main thread so dont dispatch back to main.
                            if didSetCredentials, let accessToken = strongSelf.accessToken {
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

}
