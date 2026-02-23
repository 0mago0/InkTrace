//
//  FontHelper.swift
//  InkTrace
//
//  動態字體選擇工具：使用 CoreText 檢測字形支援並提供回退機制
//

import SwiftUI
import CoreText
import UIKit

struct FontHelper {

    // MARK: - 手動註冊字體（繞過 Info.plist 的 UIAppFonts）

    /// 是否已完成字體註冊
    private static var fontsRegistered = false

    /// 在 App 啟動時呼叫，手動從 Bundle 註冊所有 .ttf 字體
    static func registerBundledFonts() {
        guard !fontsRegistered else { return }
        fontsRegistered = true

        let fontExtensions = ["ttf", "otf"]
        for ext in fontExtensions {
            guard let fontURLs = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) else { continue }
            for url in fontURLs {
                var errorRef: Unmanaged<CFError>?
                let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)
                if success {
                    print("✅ 已註冊字體: \(url.lastPathComponent)")
                } else {
                    // kCTFontManagerErrorAlreadyRegistered = 105，可以忽略
                    if let error = errorRef?.takeRetainedValue() {
                        let code = CFErrorGetCode(error)
                        if code == 105 {
                            print("ℹ️ 字體已註冊（跳過）: \(url.lastPathComponent)")
                        } else {
                            print("❌ 註冊字體失敗: \(url.lastPathComponent) - \(error)")
                        }
                    }
                }
            }
        }

        // 註冊完畢後列出所有可用的自訂字體名稱
        print("📋 已註冊的字體族群:")
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            // 只印出我們 bundle 的字體（過濾系統字體）
            for name in names {
                if customFontCandidates.contains(name) {
                    print("   ✅ \(family) → \(name)")
                }
            }
        }
    }

    // MARK: - 字形可用性檢測

    /// 檢查指定字體是否包含能渲染該字串所有字元的字形
    static func fontContainsGlyphs(for string: String, fontName: String, size: CGFloat) -> Bool {
        guard let uiFont = UIFont(name: fontName, size: size) else { return false }
        let ctFont = uiFont as CTFont
        let utf16 = Array(string.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
        return CTFontGetGlyphsForCharacters(ctFont, utf16, &glyphs, utf16.count)
    }

    /// 使用 CoreText 的 cascade 機制，為給定字串找到可以渲染的字體
    /// 這會搜尋系統所有已安裝的字體（包括 bundle 的自訂字體）
    static func findFallbackUIFont(for string: String, size: CGFloat) -> UIFont? {
        let baseFont = CTFontCreateWithName("Helvetica" as CFString, size, nil)
        let cfString = string as CFString
        let length = CFStringGetLength(cfString)
        guard length > 0 else { return nil }

        let fallback = CTFontCreateForString(baseFont, cfString, CFRangeMake(0, length))
        let fallbackName = CTFontCopyPostScriptName(fallback) as String

        // 如果 CoreText 回傳 LastResort，代表沒有任何字體能渲染此字元
        if fallbackName == ".LastResort" || fallbackName.contains("LastResort") {
            return nil
        }

        return fallback as UIFont
    }

    // MARK: - SwiftUI Font 選擇

    /// 自訂字體候選清單（依優先順序）
    private static let customFontCandidates = [
        "NotoSansTC-Regular",       // Noto Sans TC（繁體中文）
        "NotoSans-Regular",         // Noto Sans（拉丁 + 部分 Unicode）
    ]

    /// 為指定字元選擇最佳的 SwiftUI Font
    /// 優先順序：自訂字體 → CoreText 系統回退字體 → 系統預設字體
    static func bestFont(for character: String, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // 1. 依序嘗試自訂字體
        for fontName in customFontCandidates {
            if fontContainsGlyphs(for: character, fontName: fontName, size: size) {
                return .custom(fontName, size: size)
            }
        }

        // 2. 嘗試 CoreText cascade 回退，搜尋系統已安裝字體
        if let fallbackFont = findFallbackUIFont(for: character, size: size) {
            let name = fallbackFont.fontName
            return .custom(name, size: size)
        }

        // 3. 最後回退到系統字體（SwiftUI 會自動嘗試系統 cascade）
        return .system(size: size, weight: weight)
    }

    /// 為指定字元選擇最佳的 UIFont（用於 PencilKit / CoreGraphics 等場景）
    static func bestUIFont(for character: String, size: CGFloat) -> UIFont {
        // 1. 依序嘗試自訂字體
        for fontName in customFontCandidates {
            if fontContainsGlyphs(for: character, fontName: fontName, size: size),
               let font = UIFont(name: fontName, size: size) {
                return font
            }
        }

        // 2. CoreText cascade 回退
        if let fallbackFont = findFallbackUIFont(for: character, size: size) {
            return fallbackFont
        }

        // 3. 系統預設
        return .systemFont(ofSize: size)
    }

    /// 診斷工具：印出字元的字體支援情況（開發期間使用）
    static func debugFontSupport(for character: String) {
        let scalars = character.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: ", ")
        print("🔍 字元: \"\(character)\" (\(scalars))")

        for fontName in customFontCandidates {
            let supported = fontContainsGlyphs(for: character, fontName: fontName, size: 16)
            print("   \(fontName): \(supported ? "✅ 支援" : "❌ 不支援")")
        }

        if let fallback = findFallbackUIFont(for: character, size: 16) {
            print("   CoreText 回退字體: \(fallback.fontName) ✅")
        } else {
            print("   CoreText 回退: ❌ 無可用字體（可能需要手動加入字體檔案）")
        }
    }
}
