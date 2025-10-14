//
//  XTokenCredentials.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/22/25.
//

import Foundation

/**
 * A data model struct encapsulating X API's token credentials
 * for a "authorized and authenticated" user. Do NOT log this object
 * or write it to disk, this should be a temporary in-memory object that
 * is quickly discarded. If you'd like to persist this consider XUserSession
 * object's API where you can securely persist these credentials and manage
 * an "active" session.
 */
public struct XTokenCredentialsModel: Decodable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: TimeInterval
    public let expiresAt: TimeInterval
    public let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        expiresIn = try container.decode(TimeInterval.self, forKey: .expiresIn)
        expiresAt = Date().timeIntervalSince1970 + expiresIn
        tokenType = try container.decode(String.self, forKey: .tokenType)
    }
}
