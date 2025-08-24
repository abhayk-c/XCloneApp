//
//  XAssertsPreconditions.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/23/25.
//

import Foundation

public func preconditionMainThread(_ message: String = "API must be called on Main Thread") {
    precondition(Thread.isMainThread, message)
}
