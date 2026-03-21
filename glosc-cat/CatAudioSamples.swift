//
//  CatAudioSamples.swift
//  glosc-cat
//
//  Created by GitHub Copilot on 2026/3/21.
//

import Foundation

struct CatAudioSample: Identifiable, Equatable {
    let id: String
    let title: String
    let intent: String
    let detail: String
    let fileName: String
    let fileExtension: String
    let attribution: String
    let license: String
    let recommendedTone: CatTone?
    let keywords: [String]

    var bundleURL: URL? {
        Bundle.main.url(forResource: fileName, withExtension: fileExtension, subdirectory: "CatAudio")
    }

    var fullFileName: String {
        "\(fileName).\(fileExtension)"
    }

    var canPlayInApp: Bool {
        ["mp3", "wav", "m4a", "caf", "aif", "aiff"].contains(fileExtension.lowercased())
    }

    static let builtIn: [CatAudioSample] = [
        CatAudioSample(
            id: "food_request",
            title: "想吃东西",
            intent: "饭点提醒",
            detail: "母英国短毛猫想要食物，适合演示偏明确的需求表达。",
            fileName: "food_request_british_shorthair",
            fileExtension: "mp3",
            attribution: "Wikimedia Commons: Weibliche Britisch Kurzhaar will Futter C1277 MIAUEN.wav",
            license: "CC BY 4.0",
            recommendedTone: .call,
            keywords: ["吃", "饭", "饿", "零食", "开饭", "喝水"]
        ),
        CatAudioSample(
            id: "pleading_outside",
            title: "请求出门",
            intent: "想出去看看",
            detail: "节奏更主动，适合演示急切但不算攻击性的提醒型猫叫。",
            fileName: "pleading_to_go_out",
            fileExtension: "mp3",
            attribution: "Wikimedia Commons: Meow of a pleading cat.oga",
            license: "Public Domain",
            recommendedTone: .call,
            keywords: ["来", "过来", "回家", "门", "出去", "跟我走"]
        ),
        CatAudioSample(
            id: "impatient_outside",
            title: "出门前不耐烦",
            intent: "等不及了",
            detail: "更像已经知道要出门时的催促，适合演示不耐烦和催促感。",
            fileName: "impatient_to_go_out",
            fileExtension: "mp3",
            attribution: "Wikimedia Commons: GettingOutImpatient.ogg",
            license: "Public Domain",
            recommendedTone: .play,
            keywords: ["快点", "陪玩", "玩", "起来", "出门", "马上"]
        ),
        CatAudioSample(
            id: "siamese_meow",
            title: "暹罗猫叫",
            intent: "高辨识度喵叫",
            detail: "音色更尖一点，适合做更典型的猫叫试听示例。",
            fileName: "siamese_meow",
            fileExtension: "wav",
            attribution: "Wikimedia Commons: Meow of a Siamese cat - freemaster2.wav",
            license: "CC0",
            recommendedTone: .praise,
            keywords: ["乖", "真棒", "好棒", "喜欢你", "夸", "抱抱", "亲亲"]
        ),
        CatAudioSample(
            id: "heat_call",
            title: "持续呼叫",
            intent: "持续高存在感",
            detail: "连续感更强，适合展示更长、更抓人的猫叫节奏。",
            fileName: "in_heat_call",
            fileExtension: "mp3",
            attribution: "Wikimedia Commons: Audio file of cat meowing.ogg",
            license: "CC BY-SA 4.0",
            recommendedTone: .play,
            keywords: ["注意", "听我说", "互动", "兴奋", "回应", "看我"]
        )
    ]

    static func demoSample(for tone: CatTone) -> CatAudioSample {
        builtIn.first(where: { $0.recommendedTone == tone }) ?? builtIn[0]
    }

    static func bestMatch(for text: String, tone: CatTone) -> CatAudioSample {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)

        return builtIn.max { lhs, rhs in
            score(for: lhs, text: normalized, tone: tone) < score(for: rhs, text: normalized, tone: tone)
        } ?? demoSample(for: tone)
    }

    private static func score(for sample: CatAudioSample, text: String, tone: CatTone) -> Int {
        var total = 0

        if sample.recommendedTone == tone {
            total += 8
        }

        for keyword in sample.keywords where text.contains(keyword) {
            total += 6
        }

        if tone == .soothe && sample.id == "siamese_meow" {
            total += 2
        }

        if tone == .play && sample.id == "impatient_outside" {
            total += 3
        }

        return total
    }
}