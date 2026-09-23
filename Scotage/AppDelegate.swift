import UIKit
import Alamofire
import OneSignalFramework

final class AppDelegate: NSObject, UIApplicationDelegate {
    private static let bind = "com.scotage.face"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = Self.bind
        APIConfig.apply()
        OneSignal.initialize("e0e3bb06-a7fe-4a2a-9e9a-2abca3925961", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ @Sendable _ in }, fallbackToSettings: false)
        application.registerForRemoteNotifications()
        return true
    }
}
