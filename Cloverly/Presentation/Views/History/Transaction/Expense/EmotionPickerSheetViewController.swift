//
//  EmotionPickerSheetViewController.swift
//  Cloverly
//
//  Created by 이인호 on 5/21/26.
//

import UIKit
import SnapKit
import RxSwift

class EmotionPickerSheetViewController: UIViewController {
    var onSelect: ((Emotion) -> Void)?
    private var currentEmotion: Emotion?
    private let disposeBag = DisposeBag()

    // MARK: - UI

    private lazy var titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "감정"
        label.typography = .t1
        label.textColor = .gray1
        return label
    }()

    private lazy var xButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "Modal Close Button"), for: .normal)
        btn.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        return btn
    }()

    private let emotionGridView = EmotionGridView()

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
            if let emotion = currentEmotion {
                onSelect?(emotion)
            }
            dismiss(animated: true)
        }, for: .touchUpInside)
        return btn
    }()

    // MARK: - Init

    init(emotion: Emotion?) {
        self.currentEmotion = emotion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        updateConfirmButton(enabled: currentEmotion != nil)

        emotionGridView.selectedEmotion
            .subscribe(onNext: { [weak self] emotion in
                self?.currentEmotion = emotion
                self?.updateConfirmButton(enabled: true)
            })
            .disposed(by: disposeBag)
    }

    private func updateConfirmButton(enabled: Bool) {
        confirmButton.isEnabled = enabled
        confirmButton.backgroundColor = enabled ? .green5 : .gray8
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let emotion = currentEmotion {
            emotionGridView.select(emotion: emotion)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(xButton)
        view.addSubview(emotionGridView)
        view.addSubview(confirmButton)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.leading.equalToSuperview().offset(20)
        }

        xButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-20)
        }

        emotionGridView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(268)
        }

        confirmButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(56)
        }
    }
}
