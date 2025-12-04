//
//  XSettingsViewController.swift
//  XCloneApp
//
//  Created by Abhay Curam on 12/3/25.
//

import UIKit

public protocol XSettingsViewControllerDelegate: AnyObject {
    func settingsViewControllerUserDidSignOut()
}

public class XSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    public weak var delegate: XSettingsViewControllerDelegate?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.settingsTableViewCellReuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var logoutSpinnerView: UIActivityIndicatorView = {
        let spinnerView = UIActivityIndicatorView(style: .large)
        spinnerView.color = UIColor.lightGray
        spinnerView.hidesWhenStopped = true
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        return spinnerView
    }()
    
    private let userSession: XUserSession
    private let debouncer = XDebouncer(0.5)
    
    private var shouldDisplayLogoutSpinner: Bool = false {
        didSet {
            if shouldDisplayLogoutSpinner {
                if logoutSpinnerView.isHidden { logoutSpinnerView.isHidden = false }
                logoutSpinnerView.startAnimating()
            } else {
                logoutSpinnerView.stopAnimating()
                if logoutSpinnerView.isHidden { logoutSpinnerView.isHidden = true }
            }
        }
    }
    
    private struct Constants {
        static let navigationTitle = "Settings"
        static let settingsTableViewCellReuseId = "settings-table-view-cell"
        static let signOutCellText = "Sign Out"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(_ userSession: XUserSession, _ delegate: XSettingsViewControllerDelegate?) {
        self.userSession = userSession
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        navigationItem.title = Constants.navigationTitle
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        view.addSubview(tableView)
        view.addSubview(logoutSpinnerView)
        setupConstraints()
    }
    
    // MARK: UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var settingsCell = UITableViewCell(style: .default, reuseIdentifier: Constants.settingsTableViewCellReuseId)
        if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: Constants.settingsTableViewCellReuseId) {
            settingsCell = dequeuedCell
        }
        settingsCell.textLabel?.text = Constants.signOutCellText
        return settingsCell
    }
    
    // MARK: UITableViewDelegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.allowsSelection = false
        shouldDisplayLogoutSpinner = true
        tableView.deselectRow(at: indexPath, animated: true)
        debouncer.perform { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.userSession.invalidateSession { [weak self] (didInvalidate, error) in
                guard let strongSelf = self else { return }
                if didInvalidate && error == nil {
                    strongSelf.delegate?.settingsViewControllerUserDidSignOut()
                }
                strongSelf.shouldDisplayLogoutSpinner = false
                strongSelf.tableView.allowsSelection = true
            }
        }
    }
    
    // MARK: Private Helpers
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            logoutSpinnerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutSpinnerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
}
