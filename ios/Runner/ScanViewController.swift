//
//  ScanViewController.swift
//  Runner
//
//  Created by Qiu Jishuai on 2020/11/19.
//

import Scanner

class ScanViewController: CodeScannerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let cancel = UIButton.init(type: .system)
        cancel.setTitle("取消", for: .normal)
        cancel.setTitleColor(.white, for: .normal)
        cancel.addTarget(self, action: #selector(touchCancel), for: .touchUpInside)

        view.addSubview(cancel)
        cancel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(15)
            $0.width.equalTo(60)
            $0.height.equalTo(44)
            $0.top.equalToSuperview().offset(windowSafeAreaInsets.top + 20)
        }
    }

    @objc func touchCancel() {
        completionBlock?(nil)
    }
}
