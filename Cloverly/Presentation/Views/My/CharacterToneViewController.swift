//
//  CharacterToneViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/28/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class CharacterToneViewController: UIViewController {
    let viewModel: MyViewModel
    let boxA = SelectionBoxView()
    let boxB = SelectionBoxView()
    private let disposeBag = DisposeBag()
    
    init(viewModel: MyViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "캐릭터 말투 변경"
        bind()
        configureUI()
    }
    
    func configureUI() {
        view.addSubview(boxA)
        view.addSubview(boxB)
        
        boxA.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        boxB.snp.makeConstraints {
            $0.top.equalTo(boxA.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        boxA.setContents(
            imoji: "🥹",
            title: "공감형",
            subtitle: "“너 오늘 진짜 애썼구나..\n그래서 보상하고 싶었던 거지?”"
        )
        
        boxB.setContents(
            imoji: "🤖",
            title: "목표지향형",
            subtitle: "“이 지출이 어떤 의미인지 같이 정리해볼까?”"
        )
    }
    
    func bind() {
        let tapA = UITapGestureRecognizer()
        boxA.addGestureRecognizer(tapA)
        
        let tapB = UITapGestureRecognizer()
        boxB.addGestureRecognizer(tapB)
        
        tapA.rx.event
            .map { _ in 0 }
            .bind(to: viewModel.selectedIndex)
            .disposed(by: disposeBag)
        
        tapB.rx.event
            .map { _ in 1 }
            .bind(to: viewModel.selectedIndex)
            .disposed(by: disposeBag)
        
        viewModel.selectedIndex
            .subscribe(onNext: { [weak self] index in
                self?.boxA.isSelectedBox = (index == 0)
                self?.boxB.isSelectedBox = (index == 1)
            })
            .disposed(by: disposeBag)
    }
}
