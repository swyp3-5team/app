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
    private var currentEmotion: Emotion
    private let disposeBag = DisposeBag()

    // MARK: - UI

    private lazy var titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "소비감정"
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
            onSelect?(currentEmotion)
            dismiss(animated: true)
        }, for: .touchUpInside)
        return btn
    }()

    // MARK: - Init

    init(emotion: Emotion) {
        self.currentEmotion = emotion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()

        emotionGridView.selectedEmotion
            .subscribe(onNext: { [weak self] emotion in
                self?.currentEmotion = emotion
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        emotionGridView.select(emotion: currentEmotion)
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(xButton)
        view.addSubview(emotionGridView)
        view.addSubview(confirmButton)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }

        xButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-16)
        }

        emotionGridView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(268)
        }

        confirmButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(56)
        }
    }
}
