//
//  MenuCardView.swift
//  Cloverly
//
//  Created by 이인호 on 5/12/26.
//

import UIKit
import SnapKit

struct MenuItem {
    let image: UIImage?
    let title: String
    let subtitle: String
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
        layer.cornerRadius = 16

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.verticalEdges.equalToSuperview().inset(8)
        }

        for item in items {
            stackView.addArrangedSubview(makeRow(item: item))
        }
    }

    private func makeRow(item: MenuItem) -> UIView {
        let button = UIButton()
        button.addAction(UIAction { _ in item.action() }, for: .touchUpInside)

        let imageView = UIImageView(image: item.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .gray1
        imageView.isUserInteractionEnabled = false

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = Typography.b1.uiFont
        titleLabel.textColor = .gray1
        titleLabel.isUserInteractionEnabled = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = item.subtitle
        subtitleLabel.font = Typography.b4.uiFont
        subtitleLabel.textColor = .gray1
        subtitleLabel.isUserInteractionEnabled = false

        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 0
        labelStack.isUserInteractionEnabled = false

        let hStack = UIStackView(arrangedSubviews: [imageView, labelStack])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.isUserInteractionEnabled = false

        button.addSubview(hStack)
        hStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 16))
        }

        imageView.snp.makeConstraints {
            $0.width.height.equalTo(36)
        }

        return button
    }
}
