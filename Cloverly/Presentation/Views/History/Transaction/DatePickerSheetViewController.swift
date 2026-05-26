//
//  DatePickerSheetViewController.swift
//  Cloverly
//
//  Created by 이인호 on 5/20/26.
//

import UIKit
import SnapKit

class DatePickerSheetViewController: UIViewController {
    var onConfirm: ((Date) -> Void)?

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.locale = Locale(identifier: "ko_KR")
        picker.tintColor = .green5
        return picker
    }()

    private lazy var confirmButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("확인", for: .normal)
        btn.setTitleColor(.gray10, for: .normal)
        btn.titleLabel?.font = Typography.b1.uiFont
        btn.backgroundColor = .green5
        btn.layer.cornerRadius = 8
        btn.clipsToBounds = true
        btn.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            onConfirm?(datePicker.date)
            dismiss(animated: true)
        }, for: .touchUpInside)
        return btn
    }()

    init(date: Date) {
        super.init(nibName: nil, bundle: nil)
        datePicker.date = date
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        view.addSubview(datePicker)
        view.addSubview(confirmButton)

        datePicker.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        confirmButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(56)
        }
    }
}
