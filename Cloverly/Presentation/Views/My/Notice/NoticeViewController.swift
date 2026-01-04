//
//  NoticeViewController.swift
//  Cloverly
//
//  Created by 이인호 on 12/28/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class NoticeViewController: UIViewController {
    
    private let viewModel: MyViewModel
    private let disposeBag = DisposeBag()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.register(NoticeListCell.self, forCellReuseIdentifier: NoticeListCell.identifier)
        tv.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 80
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()
    
    init(viewModel: MyViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "공지사항"
        
        configureUI()
        bind()
        
        viewModel.getNotices()
    }
    
    private func configureUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func bind() {
        viewModel.notices
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension NoticeViewController: UITableViewDataSource, UITableViewDelegate {
    
    // 1. 행 개수 (ViewModel의 Relay 값에 직접 접근)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.notices.value.count
    }
    
    // 2. 셀 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoticeListCell.identifier, for: indexPath) as? NoticeListCell else {
            return UITableViewCell()
        }
        
        let notice = viewModel.notices.value[indexPath.row]
        cell.configure(with: notice)
        cell.selectionStyle = .none
        
        return cell
    }
    
    // 3. 셀 클릭 (상세 화면 이동)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 클릭된 데이터 가져오기
        let notice = viewModel.notices.value[indexPath.row]
        
        // 상세 화면 이동
        let detailVC = NoticeDetailViewController(notice: notice)
        navigationController?.pushViewController(detailVC, animated: true)
        
        // (선택 사항) 클릭 표시 바로 없애기
        // tableView.deselectRow(at: indexPath, animated: true)
    }
}
