//
//  TermsOfServiceViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/29/25.
//

import UIKit
import WebKit
import SnapKit

class TermsOfServiceViewController: UIViewController {

    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        if let url = URL(string: "https://shadow-iguanodon-ecb.notion.site/Cloverly-2c56a965517a80a6bac3d1d3f4c6e9d6") {
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
        navigationItem.title = "서비스 이용약관"
        
        view.addSubview(webView)
        
        webView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

}
