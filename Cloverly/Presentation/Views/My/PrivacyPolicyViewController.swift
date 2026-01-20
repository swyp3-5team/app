//
//  PrivacyPolicyViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/29/25.
//

import UIKit
import WebKit
import SnapKit

class PrivacyPolicyViewController: UIViewController {
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        if let url = URL(string: "https://shadow-iguanodon-ecb.notion.site/Cloverly-2025-12-23-2c56a965517a80108b6edcc016cbce35") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "개인정보 처리방침"
        
        view.addSubview(webView)
        
        webView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
