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
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    private let isIncomeMode = BehaviorRelay<Bool>(value: false)
    private let defaultExpenseMode: ExpenseEntryMode
    private let resolvedExpenseMode = BehaviorRelay<ExpenseEntryMode>(value: .multi)
    private var isDirty = false

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
            self?.navigationController?.popViewController(animated: true)
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
                    self.viewModel.refreshTrigger.accept(())
                    self.navigationController?.popViewController(animated: true)
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

    private lazy var incomeVC = IncomeViewController(viewModel: viewModel)
    private lazy var singleExpenseVC = SingleExpenseViewController(viewModel: viewModel)
    private lazy var multiExpenseVC = MultiExpenseViewController(viewModel: viewModel)
    private var currentChildVC: UIViewController?

    init(viewModel: CalendarViewModel, expenseMode: ExpenseEntryMode = .multi) {
        self.viewModel = viewModel
        self.defaultExpenseMode = expenseMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupViewMode()
        bind()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        navigationItem.titleView = titleLabel
        navigationItem.hidesBackButton = true

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

        Observable.merge(
            viewModel.currentTransaction.skip(1).map { _ in () },
            isIncomeMode.skip(1).map { _ in () },
            resolvedExpenseMode.skip(1).map { _ in () }
        )
        .subscribe(onNext: { [weak self] in
            self?.isDirty = true
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
        guard isDirty else {
            navigationController?.popViewController(animated: true)
            return
        }
        let alert = UIAlertController(
            title: "저장하지 않고 나가시겠습니까?",
            message: "변경 사항이 저장되지 않습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "나가기", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func showDeleteAlert() {
        let alert = UIAlertController(title: "내역을 삭제하시겠습니까?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            Task {
                do {
                    try await self?.viewModel.deleteTransaction()
                    self?.viewModel.refreshTrigger.accept(())
                    self?.navigationController?.popViewController(animated: true)
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
        handleBack()
        return false
    }
}
