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
    func loginViewControllerUserAuthenticationCancelled()
}

private struct XLoginViewControllerConstants {
    static let authFailedAlertTitle = "Authentication Failed"
    static let okActionAlertTitle = "OK"
}

public struct XLoginViewModel {
    public let subHeaderText: String
    public let loginButtonText: String
}

/**
 * XLoginViewController is the login VC for our XClone Application.
 * Use this VC to display our login UI to authenticate a user.
 */
public class XLoginViewController: UIViewController, XLoginStackViewDelegate, XAuthenticationManagerDelegate {

    public weak var delegate: XLoginViewControllerDelegate?
    private let viewModel: XLoginViewModel
    private let userSession: XUserSession
    private let authenticationManager: XAuthenticationManager
    
    private lazy var loginStackView: XLoginStackView = {
        let loginStackViewModel = XLoginStackViewModel(loginViewModel: viewModel, spacingConfig: XLoginStackViewSpacingConfig(.zero))
        let loginView = XLoginStackView(frame: .zero, loginStackViewModel: loginStackViewModel, delegate: self)
        loginView.translatesAutoresizingMaskIntoConstraints = false
        return loginView
    }()
    
    private lazy var loginSpinnerView: UIActivityIndicatorView = {
        let spinnerView = UIActivityIndicatorView(style: .large)
        spinnerView.color = UIColor.lightGray
        spinnerView.hidesWhenStopped = true
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        return spinnerView
    }()
    
    private var shouldDisplayLoginSpinner: Bool = false {
        didSet {
            if shouldDisplayLoginSpinner {
                loginStackView.shouldEnableLoginButton = false
                if loginSpinnerView.isHidden { loginSpinnerView.isHidden = false }
                loginSpinnerView.startAnimating()
            } else {
                loginStackView.shouldEnableLoginButton = true
                loginSpinnerView.stopAnimating()
                if loginSpinnerView.isHidden { loginSpinnerView.isHidden = true }
            }
        }
    }

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
    
    public override func viewDidLoad() {
        view.addSubview(loginStackView)
        view.addSubview(loginSpinnerView)
        setupConstraints()
    }
    
    public override func viewWillLayoutSubviews() {
        let spacingConfig = XLoginStackViewSpacingConfig(view.bounds.size)
        let loginViewModel = XLoginStackViewModel(loginViewModel: viewModel,
                                                  spacingConfig: spacingConfig)
        loginStackView.loginStackViewModel = loginViewModel
    }
    
    public func loginStackViewDidTapLoginButton(_ loginView: XLoginStackView) {
        shouldDisplayLoginSpinner = true
        authenticationManager.authenticate()
    }

    // MARK: XAuthenticationManagerDelegate
    public func presentationWindowForAuthSession() -> UIWindow? {
        return UIApplication.shared.currentSceneDelegateWindow
    }

    public func authenticationDidSucceed(_ userSession: XUserSession) {
        shouldDisplayLoginSpinner = false
        self.delegate?.loginViewControllerDidAuthenticateUser(userSession)
    }

    public func authenticationFailedWithError(_ error: XAuthenticationError) {
        shouldDisplayLoginSpinner = false
        let alertController = UIAlertController(title: XLoginViewControllerConstants.authFailedAlertTitle, message: error.localizedDescription, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: XLoginViewControllerConstants.okActionAlertTitle, style: .default) { (_) in
            alertController.dismiss(animated: true)
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true)
        self.delegate?.loginViewControllerUserAuthenticationFailed(error)
    }

    public func authenticationCancelledByUser() {
        shouldDisplayLoginSpinner = false
        self.delegate?.loginViewControllerUserAuthenticationCancelled()
    }
    
    // MARK: AutoLayout + Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            loginStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loginStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loginStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loginSpinnerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginSpinnerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

}
