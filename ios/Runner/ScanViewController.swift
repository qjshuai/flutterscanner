//
//  ScanViewController.swift
//  Runner
//
//  Created by Qiu Jishuai on 2020/11/19.
//

import Scanner
import Photos
import MBProgressHUD

class ScanViewController: CodeScannerViewController {

    let light = UIButton(type: .system)

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

        let photo = UIButton.init(type: .system)
        photo.setTitle("相册", for: .normal)
        photo.setTitleColor(.white, for: .normal)
        photo.addTarget(self, action: #selector(touchPhoto), for: .touchUpInside)

        view.addSubview(photo)
        photo.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-15)
            $0.width.equalTo(60)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().offset(-(windowSafeAreaInsets.bottom + 20))
        }

        light.setTitle(isTorchOn ? "关灯" : "开灯", for: .normal)
        light.setTitleColor(.white, for: .normal)
        light.addTarget(self, action: #selector(touchLight), for: .touchUpInside)

        view.addSubview(light)
        light.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-15)
            $0.width.equalTo(60)
            $0.height.equalTo(44)
            $0.top.equalToSuperview().offset(windowSafeAreaInsets.top + 20)
        }
    }

    @objc func touchCancel() {
        completionBlock?(nil)
    }

    private var isTorchOn: Bool {
        return AVCaptureDevice.default(for: .video)?.torchMode == .on
    }

    @objc func touchLight() {
        scanner.toggleTorch()
        light.setTitle(isTorchOn ? "关灯" : "开灯", for: .normal)
    }

    @objc func touchPhoto() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .notDetermined else {
                    self.alertNotAuth()
                    return
                }
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self
                imagePickerController.allowsEditing = false
                imagePickerController.sourceType = .photoLibrary
                self.present(imagePickerController, animated: true, completion: nil)
            }
        }
    }

    private func alertNotAuth() {
        alert(alert: "相册未授权",
              message: "请前往设置开启相册权限, 以保存图片",
              cancelAction: { },
              confirmAction: {
                DispatchQueue.main.async {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL,
                                                  options: [: ],
                                                  completionHandler: nil)
                    }
                }
              })
    }

    public func alert(_ rect: CGRect = .zero,
                      alert: String,
                      message: String? = nil,
                      cancelAction: (() -> Void)?,
                      confirmAction: (() -> Void)?,
                      cancelTitle: String? = "否",
                      confirmTitle: String? = "是") {
        let alertController = UIAlertController(title: alert, message: message, preferredStyle: .alert)
        if let cancletitle = cancelTitle {
            alertController.addAction(UIAlertAction(title: cancletitle, style: .cancel, handler: { (_) in
                cancelAction?()
            }))
        }
        if let confirmtitle = confirmTitle {
            alertController.addAction(UIAlertAction(title: confirmtitle, style: .default, handler: { (_) in
                confirmAction?()
            }))
        }
        present(alertController, animated: true, completion: nil)
        return
    }
}

extension ScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage) {
            let result = detectQRCode(image: image)
            if !result.isEmpty {
                completionBlock?(CodeScanner.Result(value: result[0], metadataType: "qr"))
                dismiss(animated: true, completion: nil)
            } else {
                let hud = MBProgressHUD.showAdded(to: view, animated: true)
                hud.mode = .text
                hud.label.text = "未识别到二维码"
                hud.hide(animated: true, afterDelay: 1)
            }
            picker.dismiss(animated: true, completion: nil)
            return
        }
        if #available(iOS 11.0, *) {
            if let asset = info[.phAsset] as? PHAsset {
                PHImageManager.default().requestImage(for: asset,
                                                      targetSize: CGSize(width: 400, height: 400),
                                                      contentMode: .aspectFit,
                                                      options: nil
                ) { (image, _) in
                    DispatchQueue.main.async {
                        if let image = image {
                            let result = self.detectQRCode(image: image)
                            if !result.isEmpty {
                                self.completionBlock?(CodeScanner.Result(value: result[0], metadataType: "qr"))
                                return
                            }
                        }
                        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                        hud.mode = .text
                        hud.label.text = "未识别到二维码"
                        hud.hide(animated: true, afterDelay: 1)

                    }
                }
            }
        } else {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            hud.mode = .text
            hud.label.text = "未识别到二维码"
            hud.hide(animated: true, afterDelay: 1)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}


