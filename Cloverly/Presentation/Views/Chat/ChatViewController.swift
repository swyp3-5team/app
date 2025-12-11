//
//  ChatViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import RxSwift
import RxCocoa

class ChatViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = ChatViewModel()
    
    var isAtBottom: Bool {
        let offsetY = collectionView.contentOffset.y
        let contentHeight = collectionView.contentSize.height
        let frameHeight = collectionView.frame.size.height
        return offsetY >= contentHeight - frameHeight - 10
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 8
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(ChatCollectionViewCell.self, forCellWithReuseIdentifier: ChatCollectionViewCell.identifier)
        cv.delegate = self
        cv.dataSource = self
        cv.keyboardDismissMode = .interactive
        
        return cv
    }()
    
    private lazy var inputBar = InputBar(viewModel: viewModel)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        bind()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom(animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override var inputAccessoryView: UIView? {
        return inputBar
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func configure() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func bind() {
        viewModel.messages
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                // 버벅임 이슈 수정 필요
                self.collectionView.reloadData()
                self.scrollToBottom(animated: false)
            })
            .disposed(by: disposeBag)
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let keyboardHeight = frame.height

        let bottomInset: CGFloat

        if keyboardHeight > 0 {
            bottomInset = keyboardHeight /*- 간격 없이 딱 view.safeAreaInsets.bottom*/
        } else {
            bottomInset = inputBar.frame.height
        }
        
        UIView.animate(withDuration: duration) {
            self.collectionView.contentInset.bottom = bottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = bottomInset

            if self.isAtBottom {
                self.scrollToBottom(animated: false)
            }
        }
    }

    func scrollToBottom(animated: Bool = true) {
        let section = 0
        let itemCount = collectionView.numberOfItems(inSection: section)
        guard itemCount > 0 else { return }

        let indexPath = IndexPath(item: itemCount - 1, section: section)

        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
}

extension ChatViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.messages.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatCollectionViewCell.identifier, for: indexPath) as? ChatCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let message = viewModel.messages.value[indexPath.row]
        cell.bind(with: message)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let estimatedFrame = viewModel.messages.value[indexPath.row].textBody.getEstimatedFrame(with: .systemFont(ofSize: 18))
        return CGSize(width: view.bounds.width, height: estimatedFrame.height + 20)
    }
}
