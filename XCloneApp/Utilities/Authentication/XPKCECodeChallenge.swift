//
//  XPKCECodeChallenge.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

import Foundation
import CryptoKit

public enum XPKCECodeChallengeMethod: String {
    case plain = "plain"
    case s256 = "S256"
}

/**
 * Helpful struct for generating PKCE parameters for use during OAuth2.0
 * Follows spec: https://www.oauth.com/oauth2-servers/pkce/
 * Inpsired by Apple's UUID class.
 */
public struct XPKCECodeChallenge {

    public let codeVerifier: String
    public let codeChallenge: String
    public let challengeMethod: XPKCECodeChallengeMethod

    public init(_ challengeMethod: XPKCECodeChallengeMethod) {
        self.challengeMethod = challengeMethod
        var str = ""
        let randSeed = Int.random(in: 2...3)
        for _ in 0..<randSeed {
            str.append(UUID().uuidString)
        }
        self.codeVerifier = str
        if challengeMethod == .plain {
            self.codeChallenge = self.codeVerifier
        } else {
            let inputData = Data(self.codeVerifier.utf8)
            let hash = SHA256.hash(data: inputData)
            self.codeChallenge = Data(hash).base64URLEncodedString()
        }
    }

}
