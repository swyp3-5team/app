//
//  ProfileViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/28/25.
//

import UIKit
import SnapKit

enum ProfileMenu: String, CaseIterable {
    case profile = "프로필"
    case account = "계정"
    case logout = "로그아웃"
    case withdraw = "회원탈퇴"
}

class ProfileViewController: UIViewController {
    
    private let menuItems = ProfileMenu.allCases
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.register(ProfileSettingCell.self, forCellReuseIdentifier: ProfileSettingCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    func configureUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "마이페이지"
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileSettingCell.identifier, for: indexPath) as? ProfileSettingCell else { return UITableViewCell() }
        
        let menu = menuItems[indexPath.row]
        cell.configure(menu: menu)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let vc = ProfileEditViewController()
            navigationController?.pushViewController(vc, animated: true)
//        case 2:
//            // 로그아웃
//        case 3:
//            // 회원탈퇴
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
