//
//  MenuCardView.swift
//  Cloverly
//
//  Created by 이인호 on 5/12/26.
//

import UIKit
import SnapKit

struct MenuItem {
    let title: String
    let action: () -> Void
}

final class MenuCardView: UIView {
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        return sv
    }()

    init(items: [MenuItem]) {
        super.init(frame: .zero)
        setupUI(items: items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(items: [MenuItem]) {
        backgroundColor = .white
        layer.cornerRadius = 12

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        for (index, item) in items.enumerated() {
            let button = UIButton()
            button.setTitle(item.title, for: .normal)
            button.setTitleColor(.gray1, for: .normal)
            button.titleLabel?.font = Typography.b3.uiFont
            button.snp.makeConstraints { $0.height.equalTo(38) }
            button.addAction(UIAction { _ in item.action() }, for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }
}
