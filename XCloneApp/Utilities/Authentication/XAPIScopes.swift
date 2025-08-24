//
//  XAPIScopes.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

public struct XAPIScopes: OptionSet {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let tweetRead = XAPIScopes(rawValue: 1 << 0)
    public static let tweetWrite = XAPIScopes(rawValue: 1 << 1)
    public static let tweetModerateWrite = XAPIScopes(rawValue: 1 << 2)
    public static let usersEmail = XAPIScopes(rawValue: 1 << 3)
    public static let usersRead = XAPIScopes(rawValue: 1 << 4)
    public static let followsRead = XAPIScopes(rawValue: 1 << 5)
    public static let followsWrite = XAPIScopes(rawValue: 1 << 6)
    public static let offlineAccess = XAPIScopes(rawValue: 1 << 7)
    public static let spaceRead = XAPIScopes(rawValue: 1 << 8)
    public static let muteRead = XAPIScopes(rawValue: 1 << 9)
    public static let muteWrite = XAPIScopes(rawValue: 1 << 10)
    public static let likeRead = XAPIScopes(rawValue: 1 << 11)
    public static let likeWrite = XAPIScopes(rawValue: 1 << 12)
    public static let listRead = XAPIScopes(rawValue: 1 << 13)
    public static let listWrite = XAPIScopes(rawValue: 1 << 14)
    public static let blockRead = XAPIScopes(rawValue: 1 << 15)
    public static let blockWrite = XAPIScopes(rawValue: 1 << 16)
    public static let bookmarkRead = XAPIScopes(rawValue: 1 << 17)
    public static let bookmarkWrite = XAPIScopes(rawValue: 1 << 18)
    public static let mediaWrite = XAPIScopes(rawValue: 1 << 19)

    public static let readTimeline: XAPIScopes = [.tweetRead, .usersRead]
    public static let readTimelineWithOfflineAccess: XAPIScopes = [.tweetRead, .usersRead, .offlineAccess]

    public func toString() -> String {
        var scopeString = ""
        if self.contains(.tweetRead) { scopeString.append("tweet.read ") }
        if self.contains(.tweetWrite) { scopeString.append("tweet.write ") }
        if self.contains(.tweetModerateWrite) { scopeString.append("tweet.moderate.write ") }
        if self.contains(.usersEmail) { scopeString.append("users.email ") }
        if self.contains(.usersRead) { scopeString.append("users.read ") }
        if self.contains(.followsRead) { scopeString.append("follows.read ") }
        if self.contains(.followsWrite) { scopeString.append("follows.write ") }
        if self.contains(.offlineAccess) { scopeString.append("offline.access ") }
        if self.contains(.spaceRead) { scopeString.append("space.read ") }
        if self.contains(.muteRead) { scopeString.append("mute.read ") }
        if self.contains(.muteWrite) { scopeString.append("mute.write ") }
        if self.contains(.likeRead) { scopeString.append("like.read ") }
        if self.contains(.likeWrite) { scopeString.append("like.write ") }
        if self.contains(.listRead) { scopeString.append("list.read ") }
        if self.contains(.listWrite) { scopeString.append("list.write ") }
        if self.contains(.blockRead) { scopeString.append("block.read ") }
        if self.contains(.blockWrite) { scopeString.append("block.write ") }
        if self.contains(.bookmarkRead) { scopeString.append("bookmark.read ") }
        if self.contains(.bookmarkWrite) { scopeString.append("bookmark.write ") }
        if self.contains(.mediaWrite) { scopeString.append("media.write ") }
        if !scopeString.isEmpty { scopeString.removeLast() }
        return scopeString
    }

}
