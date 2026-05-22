//
//  TransactionContainerViewController.swift
//  Cloverly
//
//  Created by 이인호 on 5/12/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

enum ExpenseEntryMode: Equatable {
    case single
    case multi
}

class TransactionContainerViewController: UIViewController {
    private let viewModel: TransactionViewModel
    private let onComplete: () -> Void
    private let disposeBag = DisposeBag()
    private let isIncomeMode = BehaviorRelay<Bool>(value: false)
    private let defaultExpenseMode: ExpenseEntryMode
    private let resolvedExpenseMode = BehaviorRelay<ExpenseEntryMode>(value: .multi)

    private let titleLabel: AppLabel = {
        let label = AppLabel()
        label.textColor = .gray1
        label.typography = .t1
        return label
    }()

    private lazy var xButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Modal Close Button"), for: .normal)
        button.addAction(UIAction { [weak self] _ in
            self?.handleBack()
        }, for: .touchUpInside)
        return button
    }()

    private lazy var expenseButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("지출", for: .normal)
        btn.titleLabel?.font = Typography.b5.uiFont
        btn.layer.cornerRadius = 18
        btn.clipsToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        btn.addAction(UIAction { [weak self] _ in
            self?.isIncomeMode.accept(false)
        }, for: .touchUpInside)
        return btn
    }()

    private lazy var incomeButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("수입", for: .normal)
        btn.titleLabel?.font = Typography.b5.uiFont
        btn.layer.cornerRadius = 18
        btn.clipsToBounds = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        btn.addAction(UIAction { [weak self] _ in
            self?.isIncomeMode.accept(true)
        }, for: .touchUpInside)
        return btn
    }()

    private lazy var typeButtonStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [incomeButton, expenseButton])
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("저장", for: .normal)
        button.setTitleColor(.gray6, for: .normal)
        button.titleLabel?.font = Typography.b1.uiFont
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = .gray8
        button.isEnabled = false
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            Task {
                do {
                    if !self.isIncomeMode.value && self.resolvedExpenseMode.value == .single {
                        self.singleExpenseVC.prepareSave()
                    }
                    try await self.viewModel.saveTransaction()
                    self.onComplete()
                    self.navigateBack()
                } catch {
                    print("저장 실패: \(error)")
                }
            }
        }, for: .touchUpInside)
        return button
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle("삭제", for: .normal)
        button.setTitleColor(.gray1, for: .normal)
        button.titleLabel?.font = Typography.b1.uiFont
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray7.cgColor
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.addAction(UIAction { [weak self] _ in
            self?.showDeleteAlert()
        }, for: .touchUpInside)
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [deleteButton, saveButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()

    private let containerView = UIView()
    private var originalTransaction: Transaction?

    private lazy var incomeVC = IncomeViewController(viewModel: viewModel)
    private lazy var singleExpenseVC = SingleExpenseViewController(viewModel: viewModel)
    private lazy var multiExpenseVC = MultiExpenseViewController(viewModel: viewModel)
    private var currentChildVC: UIViewController?

    init(viewModel: TransactionViewModel, expenseMode: ExpenseEntryMode = .multi, onComplete: @escaping () -> Void) {
        self.viewModel = viewModel
        self.defaultExpenseMode = expenseMode
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupViewMode()
        bind()
        // bind() 이후 스냅샷: skip(1) 덕분에 child VC의 초기 텍스트 바인딩이 currentTransaction을 수정하지 않음
        originalTransaction = viewModel.currentTransaction.value
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    private var isModal: Bool {
        navigationController?.viewControllers.first === self
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        navigationItem.titleView = titleLabel
        navigationItem.hidesBackButton = true

        if isModal {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: xButton)
        } else {
            let backButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left")?.withConfiguration(
                    UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
                ),
                style: .plain,
                target: self,
                action: #selector(handleBack)
            )
            backButton.tintColor = .gray1
            navigationItem.leftBarButtonItem = backButton
        }

        let typeButtonContainer = UIView()
        typeButtonContainer.addSubview(typeButtonStack)
        typeButtonStack.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview() }

        view.addSubview(typeButtonContainer)
        view.addSubview(containerView)
        view.addSubview(buttonStackView)

        incomeButton.snp.makeConstraints { $0.height.equalTo(36) }
        expenseButton.snp.makeConstraints { $0.height.equalTo(36) }

        typeButtonContainer.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(36)
        }

        buttonStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(56)
        }

        containerView.snp.makeConstraints {
            $0.top.equalTo(typeButtonContainer.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(buttonStackView.snp.top).offset(-10)
        }
    }

    private func setupViewMode() {
        guard let current = viewModel.currentTransaction.value else {
            titleLabel.text = "내역 추가"
            deleteButton.isHidden = true
            resolvedExpenseMode.accept(defaultExpenseMode)
            return
        }

        if current.trGroupId != -1 {
            titleLabel.text = "내역 수정"
            deleteButton.isHidden = false
            incomeButton.isEnabled = false
            expenseButton.isEnabled = false
            let isIncome = current.transactionInfoList.first?.type == "INCOME"
            isIncomeMode.accept(isIncome)
            if !isIncome {
                resolvedExpenseMode.accept(current.transactionInfoList.count <= 1 ? .single : .multi)
            }
        } else {
            titleLabel.text = "내역 추가"
            deleteButton.isHidden = true
            resolvedExpenseMode.accept(defaultExpenseMode)
        }
    }

    private func bind() {
        isIncomeMode
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateTypeButtons()
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(isIncomeMode, resolvedExpenseMode)
            .distinctUntilChanged { $0 == $1 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.switchChildVC()
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(isIncomeMode, resolvedExpenseMode)
            .flatMapLatest { [weak self] isIncome, expenseMode -> Observable<Bool> in
                guard let self else { return .just(false) }
                if isIncome { return self.incomeVC.canSave }
                return expenseMode == .single
                    ? self.singleExpenseVC.canSave
                    : self.multiExpenseVC.canSave
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isEnabled in
                self?.updateSaveButton(isEnabled: isEnabled)
            })
            .disposed(by: disposeBag)

        singleExpenseVC.requestMultiMode
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                singleExpenseVC.prepareSave()
                resolvedExpenseMode.accept(.multi)
            })
            .disposed(by: disposeBag)

        multiExpenseVC.requestSingleMode
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if var current = viewModel.currentTransaction.value,
                   let first = current.transactionInfoList.first {
                    current.transactionInfoList = [first]
                    current.totalAmount = first.amount
                    viewModel.currentTransaction.accept(current)
                }
                resolvedExpenseMode.accept(.single)
            })
            .disposed(by: disposeBag)
    }

    private func updateSaveButton(isEnabled: Bool) {
        saveButton.isEnabled = isEnabled
        saveButton.setTitleColor(isEnabled ? .gray10 : .gray6, for: .normal)
        saveButton.backgroundColor = isEnabled ? .green5 : .gray8
    }

    private func updateTypeButtons() {
        let isIncome = isIncomeMode.value
        let selectedBtn = isIncome ? incomeButton : expenseButton
        let deselectedBtn = isIncome ? expenseButton : incomeButton

        selectedBtn.backgroundColor = .gray1
        selectedBtn.setTitleColor(.gray10, for: .normal)

        deselectedBtn.backgroundColor = .gray9
        deselectedBtn.setTitleColor(.gray1, for: .normal)
    }

    private func switchChildVC() {
        let newVC: UIViewController
        if isIncomeMode.value {
            newVC = incomeVC
        } else {
            newVC = resolvedExpenseMode.value == .single ? singleExpenseVC : multiExpenseVC
        }
        guard newVC !== currentChildVC else { return }

        currentChildVC?.willMove(toParent: nil)
        currentChildVC?.view.removeFromSuperview()
        currentChildVC?.removeFromParent()

        addChild(newVC)
        containerView.addSubview(newVC.view)
        newVC.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        newVC.didMove(toParent: self)
        currentChildVC = newVC
    }

    @objc private func handleBack() {
        if hasUnsavedChanges() {
            showUnsavedChangesAlert()
        } else {
            navigateBack()
        }
    }

    private func navigateBack() {
        if isModal {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func hasUnsavedChanges() -> Bool {
        guard let current = viewModel.currentTransaction.value else { return false }

        if current.trGroupId != -1 {
            // 수정 모드: 원본 스냅샷과 비교
            guard let original = originalTransaction else { return false }

            if isIncomeMode.value || resolvedExpenseMode.value == .multi {
                return current != original
            } else {
                // 단일 지출: categoryId는 currentTransaction에 반영되지 않으므로 별도 비교
                if current != original { return true }
                return viewModel.selectedCategoryId.value != original.transactionInfoList.first?.categoryId
            }
        } else {
            // 추가 모드: 의미 있는 입력값이 있으면 true
            if isIncomeMode.value {
                return current.totalAmount > 0
                    || viewModel.selectedCategoryId.value != nil
                    || current.place?.isEmpty == false
                    || current.paymentMemo?.isEmpty == false
            } else if resolvedExpenseMode.value == .single {
                return current.totalAmount > 0
                    || viewModel.selectedCategoryId.value != nil
                    || viewModel.selectedEmotion.value != nil
                    || viewModel.selectedPayment.value != nil
                    || current.place?.isEmpty == false
                    || current.paymentMemo?.isEmpty == false
            } else {
                return !current.transactionInfoList.isEmpty
                    || viewModel.selectedEmotion.value != nil
                    || viewModel.selectedPayment.value != nil
                    || current.place?.isEmpty == false
                    || current.paymentMemo?.isEmpty == false
            }
        }
    }

    private func showUnsavedChangesAlert() {
        let alert = UIAlertController(title: "저장하지 않고 나가시겠습니까?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "나가기", style: .destructive) { [weak self] _ in
            self?.navigateBack()
        })
        present(alert, animated: true)
    }

    private func showDeleteAlert() {
        let alert = UIAlertController(title: "내역을 삭제하시겠습니까?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            Task {
                do {
                    try await self?.viewModel.deleteTransaction()
                    self?.onComplete()
                    self?.navigateBack()
                } catch {
                    print("삭제 실패: \(error)")
                }
            }
        })
        present(alert, animated: true)
    }
}

extension TransactionContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if hasUnsavedChanges() {
            showUnsavedChangesAlert()
            return false
        }
        navigationController?.popViewController(animated: true)
        return false
    }
}
