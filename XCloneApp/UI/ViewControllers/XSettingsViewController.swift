//
//  XSettingsViewController.swift
//  XCloneApp
//
//  Created by Abhay Curam on 12/3/25.
//

import UIKit

public class XSettingsViewController: UIViewController {
    
    private struct Constants {
        static let navigationTitle = "Settings"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = UIColor.white
    }
    
    private func configureNavigationItem() {
        navigationItem.title = Constants.navigationTitle
    }
    
}
