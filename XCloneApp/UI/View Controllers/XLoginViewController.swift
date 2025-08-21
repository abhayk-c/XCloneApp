//
//  XLoginViewController.swift
//  XClone
//
//  Created by Abhay Curam on 8/18/25.
//

import UIKit
import SafariServices

/**
 * XLoginViewController is the login vc for our XClone Application.
 * Use this VC to display our login UI to authenticate a user.
 */
public class XLoginViewController : UIViewController, XLoginViewDelegate, XAuthenticationManagerDelegate {
    
    private let viewModel: XLoginViewModel
    
    private lazy var authenticationManager: XAuthenticationManager = {
        let authManager = XAuthenticationManager()
        authManager.delegate = self
        return authManager
    }()
    
    public init(viewModel: XLoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
    
    public func presentationWindowForAuthSession() -> UIWindow? {
        return UIApplication.shared.currentSceneDelegateWindow
    }
    
}
