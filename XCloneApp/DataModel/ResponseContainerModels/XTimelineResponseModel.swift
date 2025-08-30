//
//  XTimelineResponseModel.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/29/25.
//

public struct XTimelineResponseModel: Decodable {
    public let data: [XDataFieldResponseModel]
    public let includes: XIncludesFieldResponseModel
    public let meta: XMetaFieldResponseModel
}

public struct XMetaFieldResponseModel: Decodable {
    public let previousToken: String?
    public let nextToken: String?
    public let resultCount: Int
    
    enum CodingKeys: String, CodingKey {
        case previousToken = "previous_token"
        case nextToken = "next_token"
        case resultCount = "result_count"
    }
}

public struct XIncludesFieldResponseModel: Decodable {
    public let users: [XUserModel]
    public let media: [XMediaAttachmentModel]
    public let usersMap: [String: XUserModel]
    public let mediaMap: [String: XMediaAttachmentModel]
    
    enum CodingKeys: String, CodingKey {
        case users
        case media
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        users = try container.decode([XUserModel].self, forKey: .users)
        media = try container.decode([XMediaAttachmentModel].self, forKey: .media)
        var userIdMap = [String: XUserModel]()
        for user in users { userIdMap[user.id] = user }
        usersMap = userIdMap
        var mediaIdMap = [String: XMediaAttachmentModel]()
        for curMedia in media { mediaIdMap[curMedia.id] = curMedia }
        mediaMap = mediaIdMap
    }
}

public struct XDataFieldResponseModel: Decodable {
    public let id: String
    public let text: String
    public let authorId: String
    public let createdTime: String
    public private(set) var attachmentIds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case authorId = "author_id"
        case createdTime = "created_at"
        case attachments = "attachments"
        case mediaKeys = "media_keys"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        authorId = try container.decode(String.self, forKey: .authorId)
        createdTime = try container.decode(String.self, forKey: .createdTime)
        if container.contains(.attachments) {
            let attachmentsContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .attachments)
            attachmentIds = try attachmentsContainer.decodeIfPresent([String].self, forKey: .mediaKeys)
        }
    }
}
