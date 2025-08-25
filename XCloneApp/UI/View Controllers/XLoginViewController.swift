//
//  XLoginViewController.swift
//  XClone
//
//  Created by Abhay Curam on 8/18/25.
//

import UIKit
import SafariServices

public protocol XLoginViewControllerDelegate: AnyObject {
    func loginViewControllerDidAuthenticateUser(_ userSession: XUserSession)
    func loginViewControllerUserAuthenticationFailed(_ error: XAuthenticationError?)
}

/**
 * XLoginViewController is the login vc for our XClone Application.
 * Use this VC to display our login UI to authenticate a user.
 */
public class XLoginViewController: UIViewController, XLoginViewDelegate, XAuthenticationManagerDelegate {

    public weak var delegate: XLoginViewControllerDelegate?
    private let viewModel: XLoginViewModel
    private let userSession: XUserSession
    private let authenticationManager: XAuthenticationManager

    // MARK: Public Init
    public init(_ userSession: XUserSession,
                _ delegate: XLoginViewControllerDelegate?,
                _ authenticationService: XAuthenticationService,
                _ viewModel: XLoginViewModel) {
        self.delegate = delegate
        self.userSession = userSession
        self.viewModel = viewModel
        self.authenticationManager = XAuthenticationManager(userSession, nil, authenticationService)
        super.init(nibName: nil, bundle: nil)
        self.authenticationManager.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let loginView = XLoginView(frame: .zero, loginViewModel: viewModel, delegate: self)
        let containerView = XSafeAreaInsetContainerView(frame: .zero, childView: loginView)
        containerView.backgroundColor = UIColor.black
        view = containerView
    }

    public func loginViewDidTapLoginButton(_ loginView: XLoginView) {
        authenticationManager.authenticate()
    }

    // MARK: XAuthenticationManagerDelegate
    public func presentationWindowForAuthSession() -> UIWindow? {
        return UIApplication.shared.currentSceneDelegateWindow
    }

    public func authenticationDidSucceed(_ userSession: XUserSession) {
        self.delegate?.loginViewControllerDidAuthenticateUser(userSession)
    }

    public func authenticationFailedWithError(_ error: XAuthenticationError) {
        self.delegate?.loginViewControllerUserAuthenticationFailed(error)
    }

}
