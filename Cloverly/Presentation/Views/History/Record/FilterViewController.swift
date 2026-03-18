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
    
    private lazy var subtitleLabel: AppLabel = {
        let label = AppLabel()
        label.text = "카테고리"
        label.textColor = .gray2
        label.typography = .b5
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumLineSpacing = 8      // 줄 간격
        layout.minimumInteritemSpacing = 8  // 아이템 간격
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize // 셀 크기 자동 계산
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(FilterCategoryCell.self, forCellWithReuseIdentifier: FilterCategoryCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.allowsMultipleSelection = true // 단일 선택
        return cv
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
            guard let self = self else { return }
            self.viewModel.tempSelectedCategories.removeAll()
            
            if let selectedItems = self.collectionView.indexPathsForSelectedItems {
                for indexPath in selectedItems {
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }
            }
            // "전체" 다시 선택
            let indexPath = IndexPath(item: 0, section: 0)
            self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
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
            guard let self = self else { return }
            self.viewModel.selectedCategories.accept(self.viewModel.tempSelectedCategories)
            self.viewModel.applyFilter()
            dismiss(animated: true)
        }, for: .touchUpInside)
        
        return button
    }()
    
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.tempSelectedCategories = viewModel.selectedCategories.value
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
    
    func configureUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: xButton)
        view.backgroundColor = .gray10
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(collectionView)
        view.addSubview(resetButton)
        view.addSubview(applyButton)

        subtitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(resetButton.snp.top).offset(-30)
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
    
    private func syncSelectionState() {
        let selected = viewModel.tempSelectedCategories
        
        if selected.isEmpty {
            // 선택된게 없으면 "전체(0번)" 선택
            collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .top)
        } else {
            // 선택된 카테고리들을 찾아서 선택 처리
            for (index, category) in viewModel.categories.enumerated() {
                if let cat = category, selected.contains(cat) {
                    collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .top)
                }
            }
        }
    }
}

extension FilterViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCategoryCell.identifier, for: indexPath) as? FilterCategoryCell else {
            return UICollectionViewCell()
        }
        
        let category = viewModel.categories[indexPath.item]
        
        // 텍스트 설정
        if let category = category {
            cell.configure(text: category.fullDisplay) // 예: "🍚 식비"
        } else {
            cell.configure(text: "전체 내역")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // A. "전체 내역(0번)"을 눌렀을 때
        if indexPath.item == 0 {
            // 다른 모든 선택 해제
            viewModel.tempSelectedCategories.removeAll()
            
            // UI에서도 0번 빼고 다 선택 해제
            for i in 1..<viewModel.categories.count {
                collectionView.deselectItem(at: IndexPath(item: i, section: 0), animated: true)
            }
            return
        }
        
        // B. 일반 카테고리를 눌렀을 때
        // 1. "전체 내역(0번)"이 선택되어 있었다면 해제
        if let selectedItems = collectionView.indexPathsForSelectedItems,
           selectedItems.contains(where: { $0.item == 0 }) {
            collectionView.deselectItem(at: IndexPath(item: 0, section: 0), animated: true)
        }
        
        // 2. ViewModel Set에 추가
        if let category = viewModel.categories[indexPath.item] {
            viewModel.tempSelectedCategories.insert(category)
        }
    }
    
    // 2. 셀 선택이 해제되었을 때 (다중 선택에서는 이것도 필요)
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // A. "전체 내역"을 끄려고 시도 -> 못 끄게 막거나, 다시 켜주기 (최소 하나는 선택되어야 한다면)
        if indexPath.item == 0 {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            return
        }
        
        // B. 일반 카테고리 해제
        if let category = viewModel.categories[indexPath.item] {
            viewModel.tempSelectedCategories.remove(category)
            
            // 만약 다 끄고 아무것도 안 남았다면? -> 자동으로 "전체" 선택
            if viewModel.tempSelectedCategories.isEmpty {
                collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: [])
            }
        }
    }
}
