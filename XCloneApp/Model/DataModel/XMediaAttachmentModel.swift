//
//  XMediaAttachmentModel.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/29/25.
//

public enum XMediaType {
    case photo
    case video
    case unknown
}

public struct XMediaAttachmentModel: Decodable {
    public let id: String
    public let mediaType: XMediaType
    public let width: Int
    public let height: Int
    public private(set) var uri: String?
    public private(set) var previewImageUri: String?
    
    enum CodingKeys: String, CodingKey {
        case width
        case height
        case uri = "url"
        case previewImageUri = "preview_image_url"
        case mediaType = "type"
        case id = "media_key"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let mediaTypeString = try container.decode(String.self, forKey: .mediaType)
        if mediaTypeString == "photo" {
            mediaType = .photo
        } else if mediaTypeString == "video" {
            mediaType = .video
        } else {
            mediaType = .unknown
        }
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        uri = try container.decodeIfPresent(String.self, forKey: .uri)
        previewImageUri = try container.decodeIfPresent(String.self, forKey: .previewImageUri)
    }
    
}
