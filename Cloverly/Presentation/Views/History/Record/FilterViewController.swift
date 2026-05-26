//
//  FilterViewController.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class FilterViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()

    private let expenseCategories = ExpenseCategory.allCases
    private let incomeCategories = IncomeCategory.allCases

    // MARK: - Views

    private lazy var titleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "필터"
        label.textColor = .gray1
        label.typography = .t1
        return label
    }()

    private lazy var xButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Modal Close Button"), for: .normal)
        button.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        return button
    }()

    // 전체 내역 chip (단독)
    private lazy var allChipCollectionView: SelfSizingCollectionView = {
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

    private lazy var expenseSubtitleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "지출"
        label.textColor = .gray2
        label.typography = .b5
        return label
    }()

    private lazy var expenseCollectionView: SelfSizingCollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let cv = SelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(FilterCategoryCell.self, forCellWithReuseIdentifier: FilterCategoryCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.allowsMultipleSelection = true
        cv.isScrollEnabled = false
        return cv
    }()

    private lazy var incomeSubtitleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "수입"
        label.textColor = .gray2
        label.typography = .b5
        return label
    }()

    private lazy var incomeCollectionView: SelfSizingCollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let cv = SelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(FilterCategoryCell.self, forCellWithReuseIdentifier: FilterCategoryCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.allowsMultipleSelection = true
        cv.isScrollEnabled = false
        return cv
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private lazy var contentStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [
            allChipCollectionView,
            expenseSubtitleLabel,
            expenseCollectionView,
            incomeSubtitleLabel,
            incomeCollectionView
        ])
        sv.axis = .vertical
        sv.spacing = 12
        sv.setCustomSpacing(20, after: allChipCollectionView)
        sv.setCustomSpacing(20, after: expenseCollectionView)
        return sv
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("초기화", for: .normal)
        button.setTitleColor(.gray1, for: .normal)
        button.titleLabel?.font = Typography.b1.uiFont
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray7.cgColor
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.tempSelectedCategories.removeAll()
            viewModel.tempSelectedIncomeCategories.removeAll()
            deselectAll(in: expenseCollectionView)
            deselectAll(in: incomeCollectionView)
            allChipCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: [])
        }, for: .touchUpInside)
        return button
    }()

    private lazy var applyButton: UIButton = {
        let button = UIButton()
        button.setTitle("적용", for: .normal)
        button.setTitleColor(.gray10, for: .normal)
        button.titleLabel?.font = Typography.b1.uiFont
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = .green5
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            viewModel.selectedCategories.accept(viewModel.tempSelectedCategories)
            viewModel.selectedIncomeCategories.accept(viewModel.tempSelectedIncomeCategories)
            viewModel.applyFilter()
            dismiss(animated: true)
        }, for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.tempSelectedCategories = viewModel.selectedCategories.value
        viewModel.tempSelectedIncomeCategories = viewModel.selectedIncomeCategories.value
        configureUI()
        syncSelectionState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let navBar = navigationController?.navigationBar else { return }
        let navBarFrameInView = navBar.convert(navBar.bounds, to: view)
        titleLabel.snp.remakeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalTo(navBarFrameInView.midY)
        }
    }

    // MARK: - UI

    func configureUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: xButton)
        view.backgroundColor = .gray10

        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        view.addSubview(resetButton)
        view.addSubview(applyButton)

        scrollView.addSubview(contentStackView)

        contentStackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(resetButton.snp.top).offset(-20)
        }

        resetButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
            $0.width.equalTo(applyButton.snp.width)
        }

        applyButton.snp.makeConstraints {
            $0.leading.equalTo(resetButton.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }
    }

    // MARK: - Selection

    private func syncSelectionState() {
        let hasExpense = !viewModel.tempSelectedCategories.isEmpty
        let hasIncome = !viewModel.tempSelectedIncomeCategories.isEmpty

        if !hasExpense && !hasIncome {
            allChipCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])
        } else {
            for (index, category) in expenseCategories.enumerated() {
                if viewModel.tempSelectedCategories.contains(category) {
                    expenseCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [])
                }
            }
            for (index, category) in incomeCategories.enumerated() {
                if viewModel.tempSelectedIncomeCategories.contains(category) {
                    incomeCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [])
                }
            }
        }
    }

    private func deselectAll(in cv: UICollectionView) {
        cv.indexPathsForSelectedItems?.forEach { cv.deselectItem(at: $0, animated: false) }
    }

    private func selectAllChip() {
        allChipCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: [])
    }

    private func deselectAllChip() {
        allChipCollectionView.deselectItem(at: IndexPath(item: 0, section: 0), animated: false)
    }
}

// MARK: - UICollectionViewDataSource, Delegate

extension FilterViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === allChipCollectionView { return 1 }
        if collectionView === expenseCollectionView { return expenseCategories.count }
        return incomeCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCategoryCell.identifier, for: indexPath) as? FilterCategoryCell else {
            return UICollectionViewCell()
        }

        if collectionView === allChipCollectionView {
            cell.configure(text: "전체 내역")
        } else if collectionView === expenseCollectionView {
            cell.configure(text: expenseCategories[indexPath.item].fullDisplay)
        } else {
            cell.configure(text: incomeCategories[indexPath.item].fullDisplay)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === allChipCollectionView {
            viewModel.tempSelectedCategories.removeAll()
            viewModel.tempSelectedIncomeCategories.removeAll()
            deselectAll(in: expenseCollectionView)
            deselectAll(in: incomeCollectionView)
            return
        }

        deselectAllChip()

        if collectionView === expenseCollectionView {
            viewModel.tempSelectedCategories.insert(expenseCategories[indexPath.item])
        } else {
            viewModel.tempSelectedIncomeCategories.insert(incomeCategories[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView === allChipCollectionView {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            return
        }

        if collectionView === expenseCollectionView {
            viewModel.tempSelectedCategories.remove(expenseCategories[indexPath.item])
        } else {
            viewModel.tempSelectedIncomeCategories.remove(incomeCategories[indexPath.item])
        }

        let nothingSelected = viewModel.tempSelectedCategories.isEmpty && viewModel.tempSelectedIncomeCategories.isEmpty
        if nothingSelected { selectAllChip() }
    }
}
