//
//  XLoginViewController.swift
//  XClone
//
//  Created by Abhay Curam on 8/18/25.
//

import UIKit
import SafariServices

public class XLoginViewController : UIViewController, XLoginViewDelegate, SFSafariViewControllerDelegate {
    
    private let viewModel: XLoginViewModel
    private let loginURI: URL?
    
    public init(viewModel: XLoginViewModel,
                loginURI: URL?) {
        self.viewModel = viewModel
        self.loginURI = loginURI
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
        guard let uri = self.loginURI else { return }
        let safariViewController = SFSafariViewController(url: uri)
        safariViewController.modalPresentationStyle = .overFullScreen
        safariViewController.delegate = self
        present(safariViewController, animated: true)
    }
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        print("Safari browser dismissed")
    }
    
}
