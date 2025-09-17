//
//  XLoginView.swift
//  XClone
//
//  Created by Abhay Curam on 8/18/25.
//

import UIKit

public struct XLoginViewModel {
    public let subHeaderText: String
    public let loginButtonText: String
    public init(subHeaderText: String, loginButtonText: String) {
        self.subHeaderText = subHeaderText
        self.loginButtonText = loginButtonText
    }
}

public protocol XLoginViewDelegate: AnyObject {
    func loginViewDidTapLoginButton(_ loginView: XLoginView)
}

private struct XLoginViewConstants {
    static let logoImageName = "x-large-logo-icon"
    static let logoImageViewYScale = 0.05
    static let labelPaddingScale = 0.112
    static let subHeaderLabelYScale = 0.0925
    static let loginButtonYScale = 0.2
}

/**
 * Our XLoginView that can be displayed and hosted in any VC or view tree.
 * Displays a X logo icon, subheader text, and a simple login button.
 */
public class XLoginView: UIView {

    public var delegate: XLoginViewDelegate?

    public var shouldDisplayLoginSpinner: Bool = false {
        didSet {
            if shouldDisplayLoginSpinner {
                loginButton.isEnabled = false
                if loginSpinnerView.isHidden { loginSpinnerView.isHidden = false }
                loginSpinnerView.startAnimating()
            } else {
                loginButton.isEnabled = true
                loginSpinnerView.stopAnimating()
                if loginSpinnerView.isHidden { loginSpinnerView.isHidden = true }
            }
        }
    }

    private var loginViewModel: XLoginViewModel

    private lazy var xLogoImageView: UIImageView = {
        let logoImage = UIImage(named: XLoginViewConstants.logoImageName)
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.tintColor = UIColor.white
        return logoImageView
    }()

    private lazy var subHeaderLabel: UILabel = {
        let subHeaderLabel = UILabel()
        subHeaderLabel.text = loginViewModel.subHeaderText
        subHeaderLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        subHeaderLabel.numberOfLines = 0
        subHeaderLabel.textColor = UIColor.white
        subHeaderLabel.lineBreakMode = .byWordWrapping
        subHeaderLabel.textAlignment = .center
        return subHeaderLabel
    }()

    private lazy var loginButton: UIButton = {
        let loginButton = UIButton(type: .system)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 36, weight: .semibold)
        loginButton.setTitleColor(UIColor.white, for: .normal)
        loginButton.setTitleColor(UIColor.darkGray, for: .disabled)
        loginButton.setTitle(loginViewModel.loginButtonText, for: .normal)
        loginButton.setTitle(loginViewModel.loginButtonText, for: .disabled)
        loginButton.addTarget(self, action: #selector(loginButtonTapped(_:)), for: .touchUpInside)
        return loginButton
    }()

    private lazy var loginSpinnerView: UIActivityIndicatorView = {
        let spinnerView = UIActivityIndicatorView(style: .large)
        spinnerView.color = UIColor.lightGray
        spinnerView.hidesWhenStopped = true
        return spinnerView
    }()

    // MARK: Public Init
    public init(frame: CGRect,
                loginViewModel: XLoginViewModel,
                delegate: XLoginViewDelegate?) {
        self.loginViewModel = loginViewModel
        self.delegate = delegate
        super.init(frame: frame)
        addSubview(self.xLogoImageView)
        addSubview(self.subHeaderLabel)
        addSubview(self.loginButton)
        addSubview(self.loginSpinnerView)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        if let xLogoImage = xLogoImageView.image {
            let xLogoImageViewY = XLoginViewConstants.logoImageViewYScale * bounds.height
            let xLogoImageViewX = (bounds.width / 2) - (xLogoImage.size.width / 2)
            xLogoImageView.frame = CGRect(x: xLogoImageViewX, y: xLogoImageViewY, width: xLogoImage.size.width, height: xLogoImage.size.height)
        }

        let scaledLabelPadding = XLoginViewConstants.labelPaddingScale * bounds.width
        let maxLabelWidth = bounds.width - (scaledLabelPadding * 2)

        let subHeaderLabelBounds = subHeaderLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))
        let subHeaderLabelYOffset = XLoginViewConstants.subHeaderLabelYScale * bounds.height
        let subHeaderLabelY = xLogoImageView.frame.origin.y + xLogoImageView.bounds.height + subHeaderLabelYOffset
        let subHeaderLabelX = (bounds.width / 2) - (subHeaderLabelBounds.width / 2)
        subHeaderLabel.frame = CGRect(x: subHeaderLabelX, y: subHeaderLabelY, width: subHeaderLabelBounds.width, height: subHeaderLabelBounds.height)

        let loginButtonBounds = loginButton.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))
        let loginButtonYOffset = XLoginViewConstants.loginButtonYScale * bounds.height
        let loginButtonY = subHeaderLabel.frame.origin.y + subHeaderLabel.bounds.height + loginButtonYOffset
        let loginButtonX = (bounds.width / 2) - (loginButtonBounds.width / 2)
        loginButton.frame = CGRect(x: loginButtonX, y: loginButtonY, width: loginButtonBounds.width, height: loginButtonBounds.height)

        let loginSpinnerBounds = loginSpinnerView.sizeThatFits(bounds.size)
        let loginSpinnerYAnchor = subHeaderLabelY + subHeaderLabelBounds.height
        let loginSpinnerYOffset = (loginButtonY - loginSpinnerYAnchor) / 2
        let loginSpinnerY = (loginSpinnerYAnchor + loginSpinnerYOffset) - (loginSpinnerBounds.height / 2)
        let loginSpinnerX = (bounds.size.width / 2) - (loginSpinnerBounds.width / 2)
        loginSpinnerView.frame = CGRect(x: loginSpinnerX, y: loginSpinnerY, width: loginSpinnerBounds.width, height: loginSpinnerBounds.height)
    }

    // MARK: XLoginViewDelegate
    @objc private func loginButtonTapped(_ sender: UIButton) {
        delegate?.loginViewDidTapLoginButton(self)
    }

}
