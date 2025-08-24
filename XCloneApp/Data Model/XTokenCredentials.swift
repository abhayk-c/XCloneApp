//
//  XTokenCredentials.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/22/25.
//

import Foundation

public struct XTokenCredentials: Decodable {
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
