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
        let candidateSubdirectories: [String?] = [
            "CatAudio",
            "Resources/CatAudio",
            "Resources",
            nil
        ]

        for subdirectory in candidateSubdirectories {
            if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension, subdirectory: subdirectory) {
                return url
            }
        }

        return nil
    }

    var fullFileName: String {
        "\(fileName).\(fileExtension)"
    }

    var canPlayInApp: Bool {
        ["mp3", "wav", "m4a", "caf", "aif", "aiff"].contains(fileExtension.lowercased())
    }

    static let builtIn: [CatAudioSample] = [
        CatAudioSample(
            id: "like_you",
            title: "喜欢你",
            intent: "亲近安抚",
            detail: "呼噜声更柔软，适合贴贴、安抚和表达喜欢时使用。",
            fileName: "clean_purr_whiskers",
            fileExtension: "mp3",
            attribution: "Wikimedia Commons: Whiskers' purr edit.ogg",
            license: "Public Domain",
            recommendedTone: .soothe,
            keywords: ["喜欢", "爱你", "贴贴", "抱抱", "亲亲", "我在这", "陪你", "别怕"]
        ),
        CatAudioSample(
            id: "meal_time",
            title: "来吃饭啦",
            intent: "开饭提醒",
            detail: "短促、明确，适合把饭点信号传递得更清楚。",
            fileName: "hungry_meow_mixkit",
            fileExtension: "mp3",
            attribution: "Mixkit: Domestic cat hungry meow",
            license: "Mixkit License",
            recommendedTone: .call,
            keywords: ["吃饭", "开饭", "吃", "饭饭", "吃东西", "来吃", "吃罐头", "吃零食"]
        ),
        CatAudioSample(
            id: "great_job",
            title: "真棒呀",
            intent: "夸奖鼓励",
            detail: "清晰又亲近，适合夸它好乖、做得真棒的时候播放。",
            fileName: "clean_meow_mixkit",
            fileExtension: "mp3",
            attribution: "Mixkit: Sweet kitty meow",
            license: "Mixkit License",
            recommendedTone: .praise,
            keywords: ["真棒", "好棒", "真乖", "好乖", "棒棒", "夸夸", "奖励"]
        ),
        CatAudioSample(
            id: "play_together",
            title: "来玩呀",
            intent: "陪玩邀请",
            detail: "更活泼一点，适合逗猫棒、追逐和互动前的邀请感。",
            fileName: "begging_meow_mixkit",
            fileExtension: "mp3",
            attribution: "Mixkit: Cartoon kitty begging meow",
            license: "Mixkit License",
            recommendedTone: .play,
            keywords: ["玩", "玩耍", "陪玩", "一起玩", "逗猫棒", "球球", "追追", "玩吧"]
        ),
        CatAudioSample(
            id: "hungry_now",
            title: "我饿啦",
            intent: "催饭表达",
            detail: "更像带一点委屈的提醒，适合表达肚子空了、想马上被注意到。",
            fileName: "distressed_meow_mixkit",
            fileExtension: "mp3",
            attribution: "Mixkit: Little cat pain meow",
            license: "Mixkit License",
            recommendedTone: .call,
            keywords: ["饿", "好饿", "肚子饿", "想吃", "给我吃", "快开饭", "饿了"]
        ),
        CatAudioSample(
            id: "come_here",
            title: "过来呀",
            intent: "召唤靠近",
            detail: "清晰、短促，适合叫它靠近你、回头看你，或从别处过来。",
            fileName: "attention_meow_mixkit",
            fileExtension: "mp3",
            attribution: "Mixkit: Little cat attention meow",
            license: "Mixkit License",
            recommendedTone: .call,
            keywords: ["过来", "来这里", "来这儿", "回来", "靠近", "来呀", "跟我来"]
        ),
        CatAudioSample(
            id: "go_away",
            title: "走开啦",
            intent: "边界提醒",
            detail: "嘶声更像在表达别靠太近，适合作为明显的拒绝或边界信号。",
            fileName: "go_away_hiss",
            fileExtension: "mp3",
            attribution: "Wikimedia Commons: Cat hissing - Zabuhailo.wav",
            license: "CC0",
            recommendedTone: nil,
            keywords: ["走开", "别过来", "不要", "不行", "住手", "离开", "别碰", "别闹"]
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

        if tone == .soothe && sample.id == "like_you" {
            total += 3
        }

        if tone == .praise && sample.id == "great_job" {
            total += 3
        }

        if tone == .play && sample.id == "play_together" {
            total += 3
        }

        return total
    }
}
