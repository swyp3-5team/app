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

class TransactionContainerViewController: UIViewController {
    private let viewModel: CalendarViewModel
    private let disposeBag = DisposeBag()
    private let isIncomeMode = BehaviorRelay<Bool>(value: false)

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
            self?.dismiss(animated: true)
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
        button.setTitleColor(.gray10, for: .normal)
        button.titleLabel?.font = Typography.b1.uiFont
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.backgroundColor = .green5
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            Task {
                do {
                    try await self.viewModel.saveTransaction()
                    self.viewModel.refreshTrigger.accept(())
                    self.dismiss(animated: true)
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
    private lazy var expenseVC = ExpenseHistoryViewController(viewModel: viewModel)
    private var currentChildVC: UIViewController?

    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        setupViewMode()
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        navigationItem.titleView = titleLabel
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: xButton)

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

    private func bind() {
        isIncomeMode
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateTypeButtons()
                self?.switchChildVC()
            })
            .disposed(by: disposeBag)
    }

    private func setupViewMode() {
        guard let current = viewModel.currentTransaction.value else {
            titleLabel.text = "내역 추가"
            deleteButton.isHidden = true
            return
        }

        if current.trGroupId != -1 {
            titleLabel.text = "내역 수정"
            deleteButton.isHidden = false
            incomeButton.isEnabled = false
            expenseButton.isEnabled = false
            isIncomeMode.accept(current.transactionInfoList.first?.type == "INCOME")
        } else {
            titleLabel.text = "내역 추가"
            deleteButton.isHidden = true
        }
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
        let newVC: UIViewController = isIncomeMode.value ? incomeVC : expenseVC
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

    private func showDeleteAlert() {
        let alert = UIAlertController(title: "내역을 삭제하시겠습니까?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            Task {
                do {
                    try await self?.viewModel.deleteTransaction()
                    self?.viewModel.refreshTrigger.accept(())
                    self?.dismiss(animated: true)
                } catch {
                    print("삭제 실패: \(error)")
                }
            }
        })
        present(alert, animated: true)
    }
}
