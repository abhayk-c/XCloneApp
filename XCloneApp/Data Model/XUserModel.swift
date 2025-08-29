//
//  XUser.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/26/25.
//

/**
 * A data model struct that encapsulate a X "user."
 */
public struct XUserModel: Decodable {
    public let id: String
    public let name: String
    public let username: String
    public let profileImageUri: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case profileImageUri = "profile_image_url"
    }
}
