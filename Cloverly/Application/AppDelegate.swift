//
//  AppDelegate.swift
//  Cloverly
//
//  Created by 이인호 on 12/11/25.
//

import UIKit
import KakaoSDKCommon
import FirebaseCore
import SDWebImage
import SDWebImageWebPCoder
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
        
        let kakaoNativeAppKey = Bundle.main.infoDictionary?["NATIVE_APP_KEY"] as? String ?? ""
        KakaoSDK.initSDK(appKey: kakaoNativeAppKey)
        
        MobileAds.shared.start()
//        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["6beba0de74aecfc2d69d8b16a04e6898"] // test
        
        Thread.sleep(forTimeInterval: 1)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

