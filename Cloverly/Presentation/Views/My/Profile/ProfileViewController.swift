//
//  ProfileViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/28/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

enum ProfileMenu: String, CaseIterable {
    case profile = "프로필"
    case account = "계정"
    case logout = "로그아웃"
    case withdraw = "회원탈퇴"
}

class ProfileViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let menuItems = ProfileMenu.allCases
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.register(ProfileSettingCell.self, forCellReuseIdentifier: ProfileSettingCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
    
    func configureUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "마이페이지"
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func bind() {
        AuthViewModel.shared.currentUser
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileSettingCell.identifier, for: indexPath) as? ProfileSettingCell else { return UITableViewCell() }
        
        let menu = menuItems[indexPath.row]
        cell.configure(menu: menu, user: AuthViewModel.shared.currentUser.value)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let vc = ProfileEditViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 2:
            showLogoutAlert()
        case 3:
            showWithdrawAlert()
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    private func showLogoutAlert() {
        let alert = UIAlertController(
            title: "로그아웃 하시겠어요?",
            message: nil,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        let logoutAction = UIAlertAction(title: "로그아웃", style: .default) { [weak self] _ in
            guard let self = self else { return }
            AuthViewModel.shared.logout()
            
            self.reloadRootView()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        
        self.present(alert, animated: true)
    }

    private func showWithdrawAlert() {
        let alert = UIAlertController(
            title: "서비스를 탈퇴하시겠어요?",
            message: "탈퇴 시 데이터가 모두 삭제되며 복구가 불가능해요.",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        let withdrawAction = UIAlertAction(title: "탈퇴할래요", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                do {
                    if AuthViewModel.shared.currentUser.value?.provider == .apple {
                        try await AuthViewModel.shared.deleteAppleUser()
                    } else {
                        try await AuthViewModel.shared.deleteKakaoUser()
                    }
                    
                    self.reloadRootView()
                } catch {
                    print("탈퇴 실패: \(error)")
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(withdrawAction)
        
        self.present(alert, animated: true)
    }
    
    private func reloadRootView() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate {
                sceneDelegate.checkAndUpdateRootViewController()
            }
        }
    }
}
