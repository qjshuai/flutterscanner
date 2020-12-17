import UIKit
import Flutter
import Scanner
import MapKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        if let controller = window.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "com.js.scanner", binaryMessenger: controller as! FlutterBinaryMessenger)
            channel.setMethodCallHandler { (call, result) in
                if call.method == "scan" {
                    guard self.checkScanPermissions() else {
                        result(nil)
                        return
                    }
                    let config = CodeScannerConfigration(
                        types: [.qr],
                        stopScanningWhenCodeIsFound: true,
                        handleOrientationChange: true,
                        rectOfInterest: CGRect(x: 0.2, y: 0.3, width: 0.6, height: 0.4),
                        sessionPreset: .high
                    )
                    let scanner = ScanViewController(configaration: config)
                    scanner.modalPresentationStyle = .fullScreen
                    scanner.completionBlock = { [weak scanner] scanResult in
                        scanner?.dismiss(animated: true, completion: nil)
                        if let value = scanResult?.value {
                            result(value)
                        } else {
                            result(nil)
                        }
                    }
                    self.window.rootViewController?.present(scanner, animated: true, completion: nil)
                } else if (call.method == "launchRoute") {
                    guard let params = call.arguments as? [String: Any],
                          let type = params["type"] as? String,
                          let address = params["address"] as? String,
                          let latitude = params["latitude"] as? Double,
                          let longitude = params["longitude"] as? Double else {
                        result(nil)
                        return
                    }
                    if (type == "amap") {
                        let scheme = URL(string: "iosamap://")!
                        if UIApplication.shared.canOpenURL(scheme) {
                            //调用高德
                            let url = "iosamap://path?sourceApplication=scanner&poiid=BGVIS&dlat=\(latitude)&dlon=\(longitude)&dev=0&style=2&dname=\(address)"
                            self.launchScheme(urlString: url)
                        } else {
                            self.launchAppStore(id: 461703208)
                        }
                    } else if (type == "baidu") {
                        let scheme = URL(string: "baidumap://")!
                        if UIApplication.shared.canOpenURL(scheme) {
                            let url =  "baidumap://map/direction?&destination=latlng:\(latitude),\(longitude)|name:\(address)&mode=driving" //transit, walking
                            self.launchScheme(urlString: url)
                        } else {
                            self.launchAppStore(id: 452186370)
                        }
                    } else {
                        let current = MKMapItem.forCurrentLocation()
                        let target = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
                        target.name = address
                        MKMapItem.openMaps(with: [current, target], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    }
                } else {
                    result(nil)
                }
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func launchAppStore(id: Int) {
        let url = URL(string: "itms-apps://itunes.apple.com/app/id\(id)")
        if !UIApplication.shared.canOpenURL(url!) {
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url!, options: [:]) { (success) in

            }
        } else {
            UIApplication.shared.openURL(url!)
        }
    }

    private func launchScheme(urlString: String) {
        let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:]) { success in

            }
        } else {
            UIApplication.shared.open(url)
        }
    }

    private func checkScanPermissions() -> Bool {
        do {
            return try CodeScanner.supportsMetadataObjectTypes()
        } catch let error as NSError {
            let alert: UIAlertController
            switch error.code {
            case -11852:
                alert = UIAlertController(title: "错误", message: "未授权相机权限, 请前往设置修改", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "设置", style: .default, handler: { (_) in
                    DispatchQueue.main.async {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL,
                                                      options: [: ],
                                                      completionHandler: nil)
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            default:
                alert = UIAlertController(title: "错误", message: "当前设备不支持扫码", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
            }
            window.rootViewController?.present(alert, animated: true, completion: nil)
            return false
        }
    }
}

let windowSafeAreaInsets: UIEdgeInsets = {
    if #available(iOS 11.0, *) {
        let window = UIApplication.shared.keyWindow ?? UIApplication.shared.windows.first
        return window?.safeAreaInsets ?? .zero
    } else {
        return .zero
    }
}()

//func topViewController() -> UIViewController? {
//    var rootViewController: UIViewController?
//    let currentWindows = UIApplication.shared.windows
//
//    for window in currentWindows {
//        if let windowRootViewController = window.rootViewController {
//            rootViewController = windowRootViewController
//            break
//        }
//    }
//    return topMost(of: rootViewController)
//}
//
//func topMost(of viewController: UIViewController?) -> UIViewController? {
//    // presented view controller
//    if let presentedViewController = viewController?.presentedViewController {
//        return topMost(of: presentedViewController)
//    }
//
//    // UITabBarController
//    if let tabBarController = viewController as? UITabBarController,
//        let selectedViewController = tabBarController.selectedViewController {
//        return topMost(of: selectedViewController)
//    }
//
//    // UINavigationController
//    if let navigationController = viewController as? UINavigationController,
//        let visibleViewController = navigationController.visibleViewController {
//        return topMost(of: visibleViewController)
//    }
//
//    // UIPageController
//    if let pageViewController = viewController as? UIPageViewController,
//        pageViewController.viewControllers?.count == 1 {
//        return topMost(of: pageViewController.viewControllers?.first)
//    }
//
//    // child view controller
//    for subview in viewController?.view?.subviews ?? [] {
//        if let childViewController = subview.next as? UIViewController {
//            return topMost(of: childViewController)
//        }
//    }
//    return viewController
//}
