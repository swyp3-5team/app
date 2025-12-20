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
    let icons = ["house.fill", "plus.circle.fill", "person.fill"]
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
    
    func configureUI() {
        backgroundColor = .gray10
        
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
//            $0.bottom.equalTo(safeAreaLayoutGuide)
        }
        
        for (index, iconName) in icons.enumerated() {
            let button = UIButton()
            button.setImage(UIImage(systemName: iconName), for: .normal)
            button.tintColor = (index == 0) ? .green : .gray
            
            var config = UIButton.Configuration.plain()

            config.image = UIImage(systemName: iconName)
            config.title = names[index]

            config.imagePlacement = .top
            config.imagePadding = 5

            var titleAttr = AttributedString(names[index])
            titleAttr.font = .customFont(.pretendardSemiBold, size: 12)
            config.attributedTitle = titleAttr

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
        updateButtonColors(selectedIndex: index)
    }
    
    private func updateButtonColors(selectedIndex: Int) {
        for (index, button) in buttons.enumerated() {
            button.tintColor = (index == selectedIndex) ? .green : .gray
        }
    }
}
