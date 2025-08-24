//
//  XHTTPRequestBuilder.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/21/25.
//

import Foundation

public enum XHTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case head = "HEAD"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
}

/**
 * A builder struct for easily creating HTTP URLRequest's
 */
public struct XHTTPRequestBuilder {
    
    public var httpMethod: XHTTPMethod = .get
    public var url: URL?
    public var httpHeaders: [XHTTPHeader] = []
    public var httpBody: [String: String] = [:]
    
    public func buildRequest() -> URLRequest? {
        guard let url = url else { return nil }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        for header in httpHeaders {
            for (key, value) in header.headerParams {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        var urlComponents = URLComponents()
        var queryItems: [URLQueryItem] = []
        for (key, value) in httpBody {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        if let data = urlComponents.percentEncodedQuery?.data(using: .utf8) {
            urlRequest.httpBody = data
        }
        return urlRequest
    }
    
}
