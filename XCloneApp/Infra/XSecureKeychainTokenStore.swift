//
//  XSecureKeychainTokenStore.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/25/25.
//

import Foundation
import Security

/*
 * XSecureKeychainTokenStore is a lightweight wrapper around iOS Keychain for secure storage.
 * Use this struct to securely persist access tokens on disk used with X's backend API.
 *
 * This object is synchronous for simplicity and to mirror the Keychain API itself,
 * but its recommended to call these API's asynchronously. Its up to the client to manage
 * this as needed.
 */
public struct XSecureKeychainTokenStore {
    
    // MARK: Public API
    public func readTokenFromKeychain(_ tokenIdentifier: String) -> (token: String?, status: OSStatus) {
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

    public func upsertTokenInKeychain(_ token: String, _ tokenIdentifier: String) -> OSStatus {
        let readToken = readTokenFromKeychain(tokenIdentifier)
        if readToken.status == errSecSuccess {
            return updateTokenInKeychain(token, tokenIdentifier)
        } else if readToken.status == errSecItemNotFound {
            return insertTokenInKeychain(token, tokenIdentifier)
        }
        return readToken.status
    }

    // MARK: Private Helpers
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
