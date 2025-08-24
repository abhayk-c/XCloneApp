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
}

public typealias XSetTokenCredentialsCompletionHandler = ((_ didSetCredentials: Bool, _ error: XUserSessionError?) -> Void)
public typealias XGetAccessTokenCompletionHandler = ((_ accessToken: String?, _ error: XUserSessionError?) -> Void)

public enum XUserSessionError {
    case keychainError(_ status: OSStatus)
    case refreshTokenFetchError(_ error: XAuthServiceError?)
}

public class XUserSession {
    
    private var accessToken: String?
    private var sessionExpiry: TimeInterval?
    private let userSessionQueue = DispatchQueue(label: "com.xcloneapp.usersession.queue", qos: .userInteractive)
    private var setTokenCredentialsCompletion: XSetTokenCredentialsCompletionHandler?
    private var getAccessTokenCompletion: XGetAccessTokenCompletionHandler?
    private var authenticationService: XAuthenticationService
    
    public init(_ authenticationService: XAuthenticationService) {
        self.authenticationService = authenticationService
    }
    
    public func didAuthenticate() -> Bool {
        return UserDefaults.standard.bool(forKey: XUserSessionConstants.authStatusDefaultsKey)
    }
    
    public func hasActiveSession() -> Bool {
        guard let accessToken = accessToken, let sessionExpiry = sessionExpiry else { return false }
        return Date().timeIntervalSince1970 < sessionExpiry
    }
    
    public func setTokenCredentials(_ tokenCredentials: XTokenCredentials,
                                    _ completion: @escaping XSetTokenCredentialsCompletionHandler) {
        if setTokenCredentialsCompletion == nil {
            setTokenCredentialsCompletion = completion
            userSessionQueue.async { [weak self] in
                if let strongSelf = self {
                    // First, lets set the access token in keychain
                    var status = strongSelf.upsertTokenInKeychain(tokenCredentials.accessToken,
                                                                  XUserSessionConstants.accessTokenKeychainId)
                    if status != errSecSuccess {
                        DispatchQueue.main.async {
                            strongSelf.setTokenCredentialsCompletion?(false, .keychainError(status))
                            strongSelf.setTokenCredentialsCompletion = nil
                        }
                    }
                    // Second, lets set the refresh token in keychain
                    status = strongSelf.upsertTokenInKeychain(tokenCredentials.refreshToken,
                                                              XUserSessionConstants.refreshTokenKeychainId)
                    if status != errSecSuccess {
                        DispatchQueue.main.async {
                            strongSelf.setTokenCredentialsCompletion?(false, .keychainError(status))
                            strongSelf.setTokenCredentialsCompletion = nil
                        }
                    }
                    // Write non-secure information to UserDefaults
                    UserDefaults.standard.set(true, forKey:XUserSessionConstants.authStatusDefaultsKey)
                    UserDefaults.standard.set(tokenCredentials.expiresAt, forKey: XUserSessionConstants.sessionExpiryDefaultsKey)
                    DispatchQueue.main.async {
                        // Now save in memory
                        strongSelf.accessToken = tokenCredentials.accessToken
                        strongSelf.sessionExpiry = tokenCredentials.expiresAt
                        strongSelf.setTokenCredentialsCompletion?(true, nil)
                        strongSelf.setTokenCredentialsCompletion = nil
                    }
                }
            }
        }
    }
    
    public func getAccessToken(_ completion: @escaping XGetAccessTokenCompletionHandler) {
        if getAccessTokenCompletion == nil {
            getAccessTokenCompletion = completion
            if let accessToken = accessToken {
                if hasActiveSession() {
                    getAccessTokenCompletion?(accessToken, nil)
                    getAccessTokenCompletion = nil
                } else {
                    userSessionQueue.async { [weak self] in
                        if let strongSelf = self {
                            strongSelf.refreshSessionAndUpdateAccessToken()
                        }
                    }
                }
            } else {
                userSessionQueue.async { [weak self] in
                    if let strongSelf = self {
                        let readAccessToken = strongSelf.readTokenFromKeychain(XUserSessionConstants.accessTokenKeychainId)
                        let sessionExpiry: TimeInterval = UserDefaults.standard.double(forKey: XUserSessionConstants.sessionExpiryDefaultsKey)
                        if readAccessToken.status == errSecSuccess, let accessToken = readAccessToken.token {
                            if Date().timeIntervalSince1970 < sessionExpiry {
                                DispatchQueue.main.async {
                                    strongSelf.accessToken = accessToken
                                    strongSelf.sessionExpiry = sessionExpiry
                                    strongSelf.getAccessTokenCompletion?(accessToken, nil)
                                }
                            } else {
                                strongSelf.refreshSessionAndUpdateAccessToken()
                            }
                        } else {
                            DispatchQueue.main.async {
                                strongSelf.getAccessTokenCompletion?(nil, .keychainError(readAccessToken.status))
                                strongSelf.getAccessTokenCompletion = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func refreshSessionAndUpdateAccessToken()
    {
        // Read refresh token from keychain
        let readRefreshToken = readTokenFromKeychain(XUserSessionConstants.refreshTokenKeychainId)
        if let refreshToken = readRefreshToken.token, readRefreshToken.status == errSecSuccess {
            // Get new access token from refresh token
            authenticationService.fetchTokenCredentialsFromRefreshToken(refreshToken,
                                                                        XAuthenticationConstants.clientID)
            { [weak self] (tokenCredentials, error) in
                // On the main thread dont dispatch back to main.
                if let strongSelf = self {
                    if error == nil, let tokenCredentials = tokenCredentials {
                        strongSelf.setTokenCredentials(tokenCredentials) { didSetCredentials, error in
                            // Already on the main thread so dont dispatch back to main.
                            if didSetCredentials, let accessToken = strongSelf.accessToken {
                                strongSelf.getAccessTokenCompletion?(accessToken, nil)
                                strongSelf.getAccessTokenCompletion = nil
                            } else {
                                strongSelf.getAccessTokenCompletion?(nil, error)
                                strongSelf.getAccessTokenCompletion = nil
                            }
                        }
                    } else {
                        strongSelf.getAccessTokenCompletion?(nil, .refreshTokenFetchError(error))
                        strongSelf.getAccessTokenCompletion = nil
                    }
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                if let strongSelf = self {
                    strongSelf.getAccessTokenCompletion?(nil, .keychainError(readRefreshToken.status))
                    strongSelf.getAccessTokenCompletion = nil
                }
            }
        }
    }
    
    private func readTokenFromKeychain(_ tokenIdentifier: String) -> (token: String?, status: OSStatus) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenIdentifier,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ] as CFDictionary
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        if status == errSecSuccess, let tokenData = result as? Data {
            let token = String(data: tokenData, encoding: .utf8)
            return (token, status)
        }
        return (nil, status)
    }
    
    private func upsertTokenInKeychain(_ token: String, _ tokenIdentifier: String) -> OSStatus {
        let readToken = readTokenFromKeychain(tokenIdentifier)
        if readToken.status == errSecSuccess {
            return updateTokenInKeychain(token, tokenIdentifier)
        } else if readToken.status == errSecItemNotFound {
            return insertTokenInKeychain(token, tokenIdentifier)
        }
        return readToken.status
    }
    
    private func insertTokenInKeychain(_ token: String, _ tokenIdentifier: String) -> OSStatus {
        guard let tokenData = token.data(using: .utf8) else { return errSecParam }
        let attributes = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenIdentifier,
            kSecValueData as String: tokenData
        ] as CFDictionary
        return SecItemAdd(attributes, nil)
    }
    
    private func updateTokenInKeychain(_ token: String, _ tokenIdentifier: String) -> OSStatus {
        guard let tokenData = token.data(using: .utf8) else { return errSecParam }
        let attributes = [kSecValueData: tokenData] as CFDictionary
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenIdentifier
        ] as CFDictionary
        return SecItemUpdate(query, attributes)
    }
    
}
