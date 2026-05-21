//
//  ExpandableListView.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import UIKit
import SnapKit

class ExpandableListView: UIView {

    var onAction: (() -> Void)?
    var onEditItem: ((Int) -> Void)?
    var onDeleteItem: ((Int) -> Void)?

    private var isExpanded = false

    // MARK: - Header

    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "지출내역"
        label.textColor = .gray2
        label.typography = .b2
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let infoButton: UIButton = {
        let btn = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        btn.setImage(UIImage(systemName: "info.circle", withConfiguration: config), for: .normal)
        btn.tintColor = .gray4
        return btn
    }()

    private lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, infoButton])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.setContentHuggingPriority(.required, for: .horizontal)
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stack
    }()

    private let summaryLabel: AppLabel = {
        let label = AppLabel()
        label.textAlignment = .right
        label.typography = .b1
        label.textColor = .gray1
        return label
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Chevron down"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private lazy var summaryStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [summaryLabel, chevronImageView])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()

    private let actionButton: UIButton = {
        let btn = UIButton(type: .custom)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Typography.b5.uiFont,
            .foregroundColor: UIColor.blueConfirm,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        btn.setAttributedTitle(NSAttributedString(string: "추가", attributes: attrs), for: .normal)
        return btn
    }()

    private let headerRow = UIView()

    // MARK: - Content

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.isHidden = true
        stack.alpha = 0
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        return stack
    }()

    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        addSubview(mainStackView)
        mainStackView.snp.makeConstraints { $0.edges.equalToSuperview() }

        mainStackView.addArrangedSubview(headerRow)
        mainStackView.addArrangedSubview(contentStackView)

        [titleStack, summaryStack, actionButton].forEach { headerRow.addSubview($0) }

        titleStack.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
        }

        actionButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        summaryStack.snp.makeConstraints {
            $0.trailing.equalTo(actionButton.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(titleStack.snp.trailing).offset(16)
        }

        chevronImageView.snp.makeConstraints { $0.width.height.equalTo(20) }

        actionButton.addAction(UIAction { [weak self] _ in
            self?.onAction?()
        }, for: .touchUpInside)

        infoButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            TooltipView.show(
                from: self.infoButton,
                text: "우측 추가 버튼을 눌러 지출 항목과\n금액, 카테고리를 입력할 수 있습니다.\n지출내역 추가 완료 시 총 금액에 반영됩니다."
            )
        }, for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
        summaryStack.addGestureRecognizer(tap)
        summaryStack.isUserInteractionEnabled = true
    }

    @objc private func handleHeaderTap() {
        isExpanded.toggle()
        UIView.animate(withDuration: 0.3) {
            self.contentStackView.isHidden = !self.isExpanded
            self.contentStackView.alpha = self.isExpanded ? 1.0 : 0.0
            self.chevronImageView.transform = CGAffineTransform(rotationAngle: self.isExpanded ? .pi : 0)
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
        }
    }

    // MARK: - Data

    func configure(with transaction: Transaction) {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let items = transaction.transactionInfoList

        guard !items.isEmpty else {
            summaryStack.isHidden = true
            UIView.performWithoutAnimation {
                contentStackView.isHidden = true
                contentStackView.alpha = 0
                isExpanded = false
            }
            return
        }

        let isSingle = items.count == 1
        for (index, item) in items.enumerated() {
            contentStackView.addArrangedSubview(
                createRowView(name: item.name, amount: item.amount, index: index, isSingleItem: isSingle)
            )
        }

        if isSingle {
            summaryStack.isHidden = true
            chevronImageView.transform = .identity
            contentStackView.isHidden = false
            contentStackView.alpha = 1.0
            isExpanded = true
        } else {
            let prevHadSummary = !summaryStack.isHidden

            let font = Typography.b1.uiFont
            let base = NSMutableAttributedString(
                string: "\(items[0].name) 외 ",
                attributes: [.foregroundColor: UIColor.gray1, .font: font]
            )
            let highlight = NSAttributedString(
                string: "\(items.count - 1)건",
                attributes: [.foregroundColor: UIColor.green5, .font: font]
            )
            base.append(highlight)
            summaryLabel.attributedText = base
            summaryStack.isHidden = false

            if !prevHadSummary {
                UIView.performWithoutAnimation {
                    isExpanded = false
                    contentStackView.isHidden = true
                    contentStackView.alpha = 0
                    chevronImageView.transform = .identity
                }
            }
        }
    }

    private func createRowView(name: String, amount: Int, index: Int, isSingleItem: Bool = false) -> UIView {
        let container = UIView()

        let nameLabel = AppLabel()
        nameLabel.text = name
        nameLabel.textColor = .gray2
        nameLabel.typography = isSingleItem ? .b1 : .b4

        let amountLabel = AppLabel()
        amountLabel.text = "\(amount.withComma)원"
        amountLabel.textColor = .gray5
        amountLabel.typography = .b4
        amountLabel.isHidden = isSingleItem

        let labelStack = UIStackView(arrangedSubviews: [nameLabel, amountLabel])
        labelStack.axis = .horizontal
        labelStack.spacing = 8

        let editButton = UIButton()
        editButton.setImage(UIImage(named: "edit icon"), for: .normal)
        editButton.addAction(UIAction { [weak self] _ in
            self?.onEditItem?(index)
        }, for: .touchUpInside)

        let deleteButton = UIButton()
        deleteButton.setImage(UIImage(named: "delete icon"), for: .normal)
        deleteButton.addAction(UIAction { [weak self] _ in
            UIView.animate(withDuration: 0.2, animations: {
                container.alpha = 0
                container.isHidden = true
                self?.contentStackView.layoutIfNeeded()
            }, completion: { _ in
                self?.onDeleteItem?(index)
            })
        }, for: .touchUpInside)

        container.addSubview(labelStack)
        container.addSubview(editButton)
        container.addSubview(deleteButton)

        labelStack.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
        }

        editButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(deleteButton.snp.leading).offset(-16)
        }

        deleteButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        return container
    }
}
