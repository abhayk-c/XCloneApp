//
//  XTweetTimelineService.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/29/25.
//

import Foundation

public enum XTweetTimelineServiceError: Error {
    case authenticationError(_ error: XUserSessionError?)
    case httpError(_ error: Error?)
    case jsonDecodeError(_ error: Error?)
}

public typealias XTweetTimelineServiceCompletionHandler = ((_ tweets: XTweetPageModel?,
                                                            _ error: XTweetTimelineServiceError?) -> Void)

public class XTweetTimelineService {
    
    private let userSession: XUserSession
    private let maxPaginationResults: Int
    private var tweetTimelineServiceCompletion: XTweetTimelineServiceCompletionHandler?
    private struct XTweetTimelineServiceConstants {
        static let endpointUriPrefix = "https://api.x.com/2/users/"
        static let endpointUriSuffix = "/timelines/reverse_chronological"
        static let paginationTokenKey = "pagination_token"
        static let maxResultsKey = "max_results"
        static let expansionsKey = "expansions"
        static let tweetFieldsKey = "tweet.fields"
        static let userFieldsKey = "user.fields"
        static let mediaFieldsKey = "media.fields"
        static let expansions = "author_id,attachments.media_keys"
        static let tweetFields = "author_id,attachments,created_at"
        static let userFields = "confirmed_email,profile_image_url"
        static let mediaFields = "height,width,url,preview_image_url"
    }
    
    public init(_ userSession: XUserSession,
                _ maxPaginationResults: Int) {
        preconditionMainThread()
        self.userSession = userSession
        self.maxPaginationResults = maxPaginationResults
    }
    
    public func fetchTweetTimeline(_ paginationToken: String? = nil,
                                   _ completion: @escaping XTweetTimelineServiceCompletionHandler) {
        preconditionMainThread()
        if tweetTimelineServiceCompletion == nil {
            tweetTimelineServiceCompletion = completion
            userSession.getUserSessionContext { [weak self] (sessionContext, error) in
                guard let strongSelf = self else { return }
                guard let sessionContext = sessionContext, error == nil else {
                    strongSelf.safelyCallTimelineServiceCompletion(nil, .authenticationError(error))
                    return
                }
                var requestBuilder = XHTTPRequestBuilder()
                requestBuilder.httpMethod = .get
                requestBuilder.httpHeaders = [XAuthorizationHTTPHeader(sessionContext.accessToken)]
                requestBuilder.url = strongSelf.buildTimelineURL(sessionContext.user.id, paginationToken)
                if let request = requestBuilder.buildRequest() {
                    let task = URLSession.shared.dataTask(with: request) { (data: Data?, _: URLResponse?, error: Error?) in
                        if let data = data, error == nil {
                            do {
                                let timelineModel = try JSONDecoder().decode(XTimelineResponseModel.self, from: data)
                                let tweetPageModel = XTweetPageModel(timelineModel)
                                DispatchQueue.main.async { [weak self] in
                                    guard let strongSelf = self else { return }
                                    strongSelf.safelyCallTimelineServiceCompletion(tweetPageModel, nil)
                                }
                            } catch {
                                DispatchQueue.main.async { [weak self] in
                                    guard let strongSelf = self else { return }
                                    strongSelf.safelyCallTimelineServiceCompletion(nil, .jsonDecodeError(error))
                                }
                            }
                        } else {
                            DispatchQueue.main.async { [weak self] in
                                guard let strongSelf = self else { return }
                                strongSelf.safelyCallTimelineServiceCompletion(nil, .httpError(error))
                            }
                        }
                    }
                    task.resume()
                }
            }
        }
    }
    
    private func safelyCallTimelineServiceCompletion(_ tweets: XTweetPageModel?,
                                                     _ error: XTweetTimelineServiceError?) {
        if let completion = tweetTimelineServiceCompletion {
            tweetTimelineServiceCompletion = nil
            completion(tweets, error)
        }
    }
    
    private func buildTimelineURL(_ userID: String, _ paginationToken: String?) -> URL? {
        let baseUri = XTweetTimelineServiceConstants.endpointUriPrefix + userID + XTweetTimelineServiceConstants.endpointUriSuffix
        var urlComponents = URLComponents(string: baseUri)
        var urlQueryItems: [URLQueryItem] = []
        urlQueryItems.append(URLQueryItem(name: XTweetTimelineServiceConstants.maxResultsKey,
                                          value: String(maxPaginationResults)))
        if let paginationToken = paginationToken {
            urlQueryItems.append(URLQueryItem(name: XTweetTimelineServiceConstants.paginationTokenKey,
                                              value: paginationToken))
        }
        urlQueryItems.append(URLQueryItem(name: XTweetTimelineServiceConstants.expansionsKey,
                                          value: XTweetTimelineServiceConstants.expansions))
        urlQueryItems.append(URLQueryItem(name: XTweetTimelineServiceConstants.tweetFieldsKey,
                                          value: XTweetTimelineServiceConstants.tweetFields))
        urlQueryItems.append(URLQueryItem(name: XTweetTimelineServiceConstants.userFieldsKey,
                                          value: XTweetTimelineServiceConstants.userFields))
        urlQueryItems.append(URLQueryItem(name: XTweetTimelineServiceConstants.mediaFieldsKey,
                                          value: XTweetTimelineServiceConstants.mediaFields))
        urlComponents?.queryItems = urlQueryItems
        return urlComponents?.url
    }
    
}
