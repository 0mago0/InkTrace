//
//  InkTraceApp.swift
//  InkTrace
//
//  Created by 張庭瑄 on 2025/9/5.
//

import SwiftUI

@main
struct InkTraceApp: App {
    init() {
        // 手動註冊 Bundle 中的所有字體（最可靠的方式）
        FontHelper.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
