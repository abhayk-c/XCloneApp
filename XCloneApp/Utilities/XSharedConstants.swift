//
//  XSharedConstants.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/21/25.
//

public struct XAuthenticationConstants {
    // URI's
    static let redirectScheme = "xcloneapp"
    static let redirectURI = redirectScheme + "://"
    static let authorizationEndpointURI = "https://x.com/i/oauth2/authorize"
    static let authTokenEndpointURI = "https://api.x.com/2/oauth2/token"
    static let revokeTokenEndpointURI = "https://api.x.com/2/oauth2/revoke"

    // Key's
    static let responseTypeKey = "response_type"
    static let clientIDKey = "client_id"
    static let redirectURIKey = "redirect_uri"
    static let codeVerifierKey = "code_verifier"
    static let codeChallengeKey = "code_challenge"
    static let codeChallengeMethodKey = "code_challenge_method"
    static let apiScopesKey = "scope"
    static let stateKey = "state"
    static let codeKey = "code"
    static let grantTypeKey = "grant_type"
    static let accessTokenKey = "access_token"
    static let refreshTokenKey = "refresh_token"
    static let tokenKey = "token"
    static let tokenTypeHintKey = "token_type_hint"

    // Values
    static let clientID = "WlNIR1ZoUWE3OTh3NElJMWM3Q2o6MTpjaQ"
    static let responseType = codeKey
    static let grantTypeAuthCode = "authorization_code"
    static let grantTypeRefreshToken = "refresh_token"
}
