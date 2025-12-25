//
//  CustomSegmentedControl.swift
//  Cloverly
//
//  Created by 이인호 on 12/20/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class CustomSegmentedControl: UIView {
    private let viewModel: ChatViewModel
    private let stackView = UIStackView()
    private let indicatorView = UIView()
    private var buttons: [UIButton] = []

    private let disposeBag = DisposeBag()

    init(viewModel: ChatViewModel, items: [String], cornerRadius: CGFloat) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI(items: items, cornerRadius: cornerRadius)
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(items: [String], cornerRadius: CGFloat) {
        backgroundColor = .gray9
        layer.cornerRadius = cornerRadius

        indicatorView.backgroundColor = .gray2
        indicatorView.layer.cornerRadius = cornerRadius
        addSubview(indicatorView)

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        for (index, title) in items.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .customFont(.pretendardSemiBold, size: 14)
            button.setTitleColor(.gray10, for: .normal)
            button.tag = index

            button.rx.tap
                .map { index }
                .bind(to: viewModel.selectedIndex)
                .disposed(by: disposeBag)

            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
    }

    private func bind() {
        viewModel.selectedIndex
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] index in
                self?.updateUI(selectedIndex: index)
            })
            .disposed(by: disposeBag)
    }

    private func updateUI(selectedIndex: Int) {
        for (i, button) in buttons.enumerated() {
            button.setTitleColor(i == selectedIndex ? .gray10 : .gray3 , for: .normal)
            button.titleLabel?.font = i == selectedIndex ? .customFont(.pretendardSemiBold, size: 14) : .customFont(.pretendardMedium, size: 14)
        }

        let target = buttons[selectedIndex]
        UIView.animate(withDuration: 0.25) {
            self.indicatorView.frame = target.frame
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        indicatorView.frame = buttons[viewModel.selectedIndex.value].frame
    }
}

