//
//  XUserIdentityService.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/26/25.
//

import Foundation

public typealias XUserIdentityServiceCompletionHandler = ((_ user: XUserModel?, _ error: XUserIdentityServiceError?) -> Void)

public enum XUserIdentityServiceError: Error {
    case emptyResponseError
    case jsonDecodingError(error: Error)
    case httpError(error: Error)
}

private struct XUserIdentityServiceConstants {
    static let endpointUri = "https://api.x.com/2/users/me"
}

/**
 * XUserIdentityService is a service object that helps fetch the current User object (identity)
 * once a user has been authorized and we have an authentication session (access token).
 * The service exchanges returns the current logged in "User" from an access token.
 * This object shouldn't have to be used directly, prefer using the XUserSession that
 * allows you to get the currently authenticated "User"
 *
 * This class is main-thread confined. Callbacks are called on the main thread,
 * all API's must be invoked on the main thread.
 */
public class XUserIdentityService {

    private var userIdentityCompletion: XUserIdentityServiceCompletionHandler?

    // MARK: Public API
    public func getUserForAccessToken(_ accessToken: String,
                                      _ completion: @escaping XUserIdentityServiceCompletionHandler) {
        preconditionMainThread()
        if userIdentityCompletion == nil {
            userIdentityCompletion = completion
            var requestBuilder = XHTTPRequestBuilder()
            requestBuilder.httpMethod = .get
            requestBuilder.httpHeaders = [XAuthorizationHTTPHeader(accessToken)]
            requestBuilder.url = URL(string: XUserIdentityServiceConstants.endpointUri)
            if let request = requestBuilder.buildRequest() {
                let task = URLSession.shared.dataTask(with: request) { (data: Data?, _: URLResponse?, error: Error?) in
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        if let error = error {
                            strongSelf.safelyCallUserIdentityCompletion(nil, .httpError(error: error))
                        } else {
                            if let data = data {
                                do {
                                    let user = try JSONDecoder().decode(XUserResponseModel.self, from: data)
                                    strongSelf.safelyCallUserIdentityCompletion(user.data, nil)
                                } catch {
                                    strongSelf.safelyCallUserIdentityCompletion(nil, .jsonDecodingError(error: error))
                                }
                            } else {
                                strongSelf.safelyCallUserIdentityCompletion(nil, .emptyResponseError)
                            }
                        }
                    }
                }
                task.resume()
            }

        }
    }

    // MARK: Private Helpers
    private func safelyCallUserIdentityCompletion(_ user: XUserModel?, _ error: XUserIdentityServiceError?) {
        if let userIdentityCompletion = userIdentityCompletion {
            self.userIdentityCompletion = nil
            userIdentityCompletion(user, error)
        }
    }

}
