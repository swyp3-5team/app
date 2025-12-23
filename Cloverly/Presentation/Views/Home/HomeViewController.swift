//
//  HomeViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit

class HomeViewController: UIViewController {
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "background"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var chatButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()

        config.title = "채팅 시작"
        config.image = UIImage(systemName: "message.fill")

        config.imagePlacement = .leading
        config.imagePadding = 4

        config.baseForegroundColor = .gray1
        config.baseBackgroundColor = .gray10
        
        var titleAttr = AttributedString.init("채팅 시작")
        titleAttr.font = .customFont(.pretendardSemiBold, size: 16)
        config.attributedTitle = titleAttr
        
        config.cornerStyle = .capsule
        
        button.configuration = config
        
        button.addAction(UIAction { [weak self] _ in
            let vc = ChatViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    func configureUI() {
        view.backgroundColor = .clear
        
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        view.addSubview(chatButton)
        
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        chatButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(40)
        }
    }
}
