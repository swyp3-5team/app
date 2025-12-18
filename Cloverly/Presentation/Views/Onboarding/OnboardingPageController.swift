//
//  OnboardingPageController.swift
//  Cloverly
//
//  Created by 이인호 on 12/18/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class BouncyButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIView.animate(withDuration: 0.05) {
                    self.alpha = 0.6
                }
            } else {
                UIView.animate(withDuration: 0.15) {
                    self.alpha = 1.0
                }
            }
        }
    }
}

struct OnboardingModel {
    let title: String
    let subtitle: String
    let imageName: String
}

class OnboardingPageController: UIViewController {
    private let disposeBag = DisposeBag()
    
    let nextTap = PublishRelay<Void>()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    init(model: OnboardingModel) {
        super.init(nibName: nil, bundle: nil)
        configure(with: model)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(imageView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(40)
            $0.leading.equalToSuperview().offset(16)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.equalTo(titleLabel)
        }
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }
    }
    
    func configure(with model: OnboardingModel) {
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        imageView.image = UIImage(named: model.imageName)
    }
}
