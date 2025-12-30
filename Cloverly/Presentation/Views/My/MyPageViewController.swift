//
//  MyPageViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/27/25.
//

import UIKit
import SnapKit
import MessageUI
import RxSwift
import RxCocoa

enum MyPageMenu: String, CaseIterable {
    case characterTone = "캐릭터 말투 변경"
    case notice = "공지사항"
    case inquiry = "문의하기"
    case termsOfService = "서비스 이용약관"
    case privacyPolicy = "개인정보 처리방침"

    var viewController: UIViewController {
        switch self {
        case .characterTone:
            return CharacterToneViewController(viewModel: MyViewModel())
        case .notice:
            return NoticeViewController()
        case .termsOfService:
            return TermsOfServiceViewController()
        case .privacyPolicy:
            return PrivacyPolicyViewController()
        default:
            return UIViewController()
        }
    }
}


class MyPageViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let menuItems = MyPageMenu.allCases
    
    var statusBarHeight: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame.height ?? 0
        }
        return 0
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "마이페이지"
        label.font = .customFont(.pretendardSemiBold, size: 18)
        label.textColor = .gray1
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        tableView.register(MenuTableViewCell.self, forCellReuseIdentifier: MenuTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        bind()
    }
    
    func configureUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.top).offset(statusBarHeight + 15.5)
            $0.centerX.equalToSuperview()
        }
        
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

extension MyPageViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 5
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as? ProfileTableViewCell else {
                return UITableViewCell()
            }
            let currentNickname = AuthViewModel.shared.currentUser.value?.nickName
                
            cell.configure(with: currentNickname)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as? MenuTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: menuItems[indexPath.row])
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let vc = ProfileViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            switch indexPath.row {
            case 2:
                if MFMailComposeViewController.canSendMail() {
                    let composeVC = MFMailComposeViewController()
                    composeVC.mailComposeDelegate = self
                    
                    // 받는 사람, 제목, 본문 설정
                    composeVC.setToRecipients(["dlrgks0909@gmail.com"])
                    composeVC.setSubject("[Cloverly] 문의 및 의견")
                    let bodyString = """
                                     
                                     -------------------
                                     이곳에 문의 내용을 적어주세요.
                                     버그 제보라면 스크린샷을 함께 첨부해주시면 큰 도움이 됩니다!
                                     -------------------
                                     
                                     [디바이스 정보]
                                     Device: \(UIDevice.current.model)
                                     OS: iOS \(UIDevice.current.systemVersion)
                                     App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                                     """
                        
                    composeVC.setMessageBody(bodyString, isHTML: false)
                    
                    self.present(composeVC, animated: true)
                } else {
                    showSendMailErrorAlert()
                }
            default:
                let menu = menuItems[indexPath.row]
                navigationController?.pushViewController(menu.viewController, animated: true)
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return UITableView.automaticDimension
    }
}

extension MyPageViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func showSendMailErrorAlert() {
        let alert = UIAlertController(
            title: "메일 전송 실패",
            message: "아이폰 이메일 설정을 확인하고 다시 시도해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
