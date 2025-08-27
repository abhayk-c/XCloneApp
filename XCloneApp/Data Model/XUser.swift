//
//  XUser.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/26/25.
//

/**
 * A data model struct encapsulate a X "user."
 */
public struct XUser: Decodable {
    public let id: String
    public let name: String
    public let username: String
}
