//
//  CustomTabBar.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class CustomTabBar: UIView {
    let itemTapped = PublishSubject<Int>()
    
    var buttons: [UIButton] = []
    let selectedIcons = ["home icon enabled", "list icon enabled", "mypage icon enabled"]
    let unselectedIcons = ["home icon disabled", "list icon disabled", "mypage icon disabled"]
    let names = ["홈", "내역", "마이"]
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyTopShadow(color: .shadow2, yOffset: -6)
    }
    
    func configureUI() {
        backgroundColor = .gray10
        
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        
        for (index, _) in names.enumerated() {
            let button = UIButton()
            
            let isSelected = (index == 0)
            let iconName = isSelected ? selectedIcons[index] : unselectedIcons[index]
            
            var config = UIButton.Configuration.plain()
            config.image = UIImage(named: iconName)
            config.title = names[index]
            config.imagePlacement = .top
            config.imagePadding = 2
            
            var titleAttr = AttributedString(names[index])
            titleAttr.font = .customFont(.pretendardSemiBold, size: 12)
            titleAttr.foregroundColor = isSelected ? .green5 : .gray3 // 색상도 초기화
            config.attributedTitle = titleAttr
            
            config.background.backgroundColor = .clear
            
            button.configuration = config
            button.contentHorizontalAlignment = .center
            
            button.tag = index
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        itemTapped.onNext(index)
        updateButtonState(selectedIndex: index)
    }
    
    func updateButtonState(selectedIndex: Int) {
        for (index, button) in buttons.enumerated() {
            let isSelected = (index == selectedIndex)
            
            var config = button.configuration
            
            let iconName = isSelected ? selectedIcons[index] : unselectedIcons[index]
            config?.image = UIImage(named: iconName)
            
            var titleAttr = AttributedString(names[index])
            titleAttr.font = .customFont(.pretendardSemiBold, size: 12)
            titleAttr.foregroundColor = isSelected ? .green5 : .gray3
            config?.attributedTitle = titleAttr
            
            button.configuration = config
        }
    }
}
