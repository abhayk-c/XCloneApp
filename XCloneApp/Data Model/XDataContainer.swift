//
//  XDataContainer.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/26/25.
//

public struct XDataContainer<T: Decodable>: Decodable {
    public let data: T
}
