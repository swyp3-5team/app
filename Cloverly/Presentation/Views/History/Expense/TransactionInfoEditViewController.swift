//
//  TransactionInfoEditViewController.swift
//  Cloverly
//
//  Created by 이인호 on 1/4/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class TransactionInfoEditViewController: UIViewController {
    
    enum Mode {
        case add
        case edit
    }
    
    // ✨ 수정 완료 후 데이터를 돌려줄 클로저
    var onSave: ((String, Int, Int) -> Void)?
    
    private let disposeBag = DisposeBag()
    
    // 초기 데이터 저장용
    private let mode: Mode
    private let initialName: String?
    private let initialAmount: Int?
    private let selectedCategoryId = BehaviorRelay<Int?>(value: nil)
    
    // MARK: - UI Components
    
    // 이름 입력 필드
    private let nameTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "지출 내역"
        label.font = .customFont(.pretendardSemiBold, size: 14)
        label.textColor = .gray2
        return label
    }()
    
    private lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "지출내역 입력"
        tf.text = initialName
        tf.font = .customFont(.pretendardRegular, size: 14)
        tf.layer.borderColor = UIColor.gray8.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 8
        tf.clipsToBounds = true
        
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        return tf
    }()
    
    // 금액 입력 필드
    private let amountTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "금액"
        label.font = .customFont(.pretendardSemiBold, size: 14)
        label.textColor = .gray2
        return label
    }()
    
    private lazy var amountTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "금액 입력"
        
        if let amount = initialAmount {
            tf.text = "\(amount)"
        }
        tf.font = .customFont(.pretendardRegular, size: 14)
        tf.keyboardType = .numberPad
        tf.layer.borderColor = UIColor.gray8.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 8
        tf.clipsToBounds = true
        
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        return tf
    }()
    
    // 카테고리 타이틀
    private let categoryTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "카테고리"
        label.font = .customFont(.pretendardSemiBold, size: 14)
        label.textColor = .gray2
        return label
    }()
    
    // 카테고리 컬렉션뷰
    private lazy var collectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(FilterCategoryCell.self, forCellWithReuseIdentifier: FilterCategoryCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.allowsMultipleSelection = false // 단일 선택
        return cv
    }()
    
    private lazy var saveButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(mode == .add ? "추가" : "저장", for: .normal)
        btn.backgroundColor = .green5
        btn.layer.cornerRadius = 8
        return btn
    }()
    
    // 데이터 소스 (전체 빼고 나머지)
    private let categories = ExpenseCategory.allCases
    
    // MARK: - Init
    init(mode: Mode = .add, name: String? = nil, amount: Int? = nil, categoryId: Int? = nil) {
        self.mode = mode
        self.initialName = name
        self.initialAmount = amount
        self.selectedCategoryId.accept(categoryId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "지출내역"
        setupUI()
        bind()
        
        // 초기 카테고리 선택
        selectInitialCategory()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupUI() {
        view.addSubview(nameTitleLabel)
        view.addSubview(nameTextField)
        view.addSubview(amountTitleLabel)
        view.addSubview(amountTextField)
        view.addSubview(categoryTitleLabel)
        view.addSubview(collectionView)
        view.addSubview(saveButton)
        
        nameTitleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().offset(16)
        }
        
        nameTextField.snp.makeConstraints {
            $0.top.equalTo(nameTitleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.width.equalTo(amountTextField.snp.width)
            $0.height.equalTo(48)
        }
        
        amountTitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameTitleLabel)
            $0.leading.equalTo(nameTextField.snp.trailing).offset(16)
        }
        
        amountTextField.snp.makeConstraints {
            $0.top.equalTo(amountTitleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(amountTitleLabel)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(48)
        }
        
        categoryTitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(categoryTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().offset(16)
            $0.height.equalTo(200)
        }
        
        saveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }
    }
    
    private func selectInitialCategory() {
        if let index = categories.firstIndex(where: { $0.rawValue == selectedCategoryId.value }) {
            let indexPath = IndexPath(item: index, section: 0)
            DispatchQueue.main.async {
                self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
        }
    }
    
    private func bind() {
        let validation = Observable.combineLatest(
            nameTextField.rx.text.orEmpty,
            amountTextField.rx.text.orEmpty,
            selectedCategoryId.asObservable()
        )
        .map { name, amount, categoryId in
            return !name.isEmpty && !amount.isEmpty && categoryId != nil
        }
        
        validation
            .subscribe(onNext: { [weak self] validate in
                guard let self = self else { return }
                
                self.saveButton.isEnabled = validate
                self.saveButton.setTitleColor(validate ? .gray10 : .gray6, for: .normal)
                self.saveButton.backgroundColor = validate ? .green5 : .gray8
            })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .withLatestFrom(Observable.combineLatest(
                nameTextField.rx.text.orEmpty,
                amountTextField.rx.text.orEmpty,
                selectedCategoryId.asObservable()
            ))
            .subscribe(onNext: { [weak self] name, amountText, categoryId in
                guard let self = self, let categoryId = categoryId else { return }
                
                // 콤마 제거 후 Int 변환
                let amountString = amountText.replacingOccurrences(of: ",", with: "")
                let amount = Int(amountString) ?? 0
                
                // 데이터 전달
                self.onSave?(name, amount, categoryId)
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - CollectionView Delegate
extension TransactionInfoEditViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCategoryCell.identifier, for: indexPath) as? FilterCategoryCell else { return UICollectionViewCell() }
        cell.configure(text: categories[indexPath.item].fullDisplay)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedCategoryId.accept(categories[indexPath.item].rawValue)
    }
}

extension TransactionInfoEditViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIButton {
            return false
        }

        return true
    }
}
