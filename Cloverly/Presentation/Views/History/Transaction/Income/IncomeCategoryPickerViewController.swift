//
//  IncomeCategoryPickerViewController.swift
//  Cloverly
//
//  Created by 이인호 on 5/20/26.
//

import UIKit
import SnapKit

class IncomeCategoryPickerViewController: UIViewController {
    var onSelect: ((IncomeCategory) -> Void)?
    private var selectedId: Int?
    private let categories = IncomeCategory.allCases

    // MARK: - UI

    private lazy var titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "카테고리"
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

    private lazy var collectionView: SelfSizingCollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let cv = SelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(FilterCategoryCell.self, forCellWithReuseIdentifier: FilterCategoryCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.allowsMultipleSelection = false
        cv.isScrollEnabled = false
        return cv
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
            guard let self,
                  let indexPath = collectionView.indexPathsForSelectedItems?.first else { return }
            onSelect?(categories[indexPath.item])
            dismiss(animated: true)
        }, for: .touchUpInside)
        return btn
    }()

    // MARK: - Init

    init(selectedId: Int?) {
        self.selectedId = selectedId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        syncSelection()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(xButton)
        view.addSubview(collectionView)
        view.addSubview(confirmButton)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        xButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        confirmButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(56)
        }
    }

    private func syncSelection() {
        guard let selectedId else { return }
        if let index = categories.firstIndex(where: { $0.rawValue == selectedId }) {
            collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [])
        }
    }
}

// MARK: - UICollectionViewDataSource, Delegate

extension IncomeCategoryPickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCategoryCell.identifier, for: indexPath) as? FilterCategoryCell else {
            return UICollectionViewCell()
        }
        cell.configure(text: categories[indexPath.item].fullDisplay)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedId = categories[indexPath.item].rawValue
    }
}
