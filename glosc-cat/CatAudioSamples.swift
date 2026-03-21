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
    let semanticEmotion: String
    let semanticNeed: String
    let semanticExplanation: String
    let semanticSuggestion: String
    let referenceSignature: CatAudioSignature
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
            semanticEmotion: "想撒娇",
            semanticNeed: "想靠近你或要一点陪伴",
            semanticExplanation: "它更像是在放松地靠近你，语气里没有明显的紧张感，反而更像想继续贴贴或被安抚。",
            semanticSuggestion: "可以先蹲下来轻声回应它，再摸摸下巴或脸颊附近，看看它会不会继续靠近。",
            referenceSignature: CatAudioSignature(duration: 3.2, averageIntensity: 0.16, peakIntensity: 0.28, activityScore: 0.18, zeroCrossingRate: 0.08, silenceRatio: 0.34),
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
            semanticEmotion: "有点急切",
            semanticNeed: "想马上吃东西或得到回应",
            semanticExplanation: "它的表达更像明确提醒你留意它，常见于等饭、催你靠近，或希望你立刻看向它的时候。",
            semanticSuggestion: "先看看饭盆、水碗和它常等你的地方，再用短一点、明确一点的回应安抚它。",
            referenceSignature: CatAudioSignature(duration: 0.92, averageIntensity: 0.52, peakIntensity: 0.78, activityScore: 0.36, zeroCrossingRate: 0.31, silenceRatio: 0.16),
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
            semanticEmotion: "想互动",
            semanticNeed: "想继续被关注和回应",
            semanticExplanation: "这类叫声通常比较平衡，没有特别尖锐的警戒感，更像是在稳定地向你发起互动。",
            semanticSuggestion: "可以顺着它的节奏看向它、叫叫名字，或者给一点轻量回应，让互动继续下去。",
            referenceSignature: CatAudioSignature(duration: 1.25, averageIntensity: 0.41, peakIntensity: 0.62, activityScore: 0.28, zeroCrossingRate: 0.24, silenceRatio: 0.18),
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
            semanticEmotion: "想互动",
            semanticNeed: "想陪玩或追逐一下",
            semanticExplanation: "节奏起伏更明显，通常不像单纯撒娇，更像在把你往玩具、窗边或移动目标上引。",
            semanticSuggestion: "可以先拿逗猫棒或轻轻移动玩具，看看它会不会立刻跟上。",
            referenceSignature: CatAudioSignature(duration: 1.4, averageIntensity: 0.45, peakIntensity: 0.71, activityScore: 0.51, zeroCrossingRate: 0.33, silenceRatio: 0.15),
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
            semanticEmotion: "有点急切",
            semanticNeed: "想马上开饭或得到回应",
            semanticExplanation: "这类叫声通常更像委屈又催促的提醒，不太像放松撒娇，而是希望你尽快做点什么。",
            semanticSuggestion: "优先检查是不是快到饭点，或者它是不是正站在饭盆、储粮处附近等你。",
            referenceSignature: CatAudioSignature(duration: 1.05, averageIntensity: 0.57, peakIntensity: 0.82, activityScore: 0.44, zeroCrossingRate: 0.29, silenceRatio: 0.14),
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
            semanticEmotion: "在轻声试探",
            semanticNeed: "想确认你有没有注意它",
            semanticExplanation: "它更像是在发出短促招呼，既没有明显不适，也不像强烈催促，更接近日常的小提醒。",
            semanticSuggestion: "先回应它一声，再观察它是不是会带你走向某个位置，或者继续看着你。",
            referenceSignature: CatAudioSignature(duration: 0.78, averageIntensity: 0.49, peakIntensity: 0.74, activityScore: 0.35, zeroCrossingRate: 0.27, silenceRatio: 0.2),
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
            semanticEmotion: "有点不安",
            semanticNeed: "需要距离和安全感",
            semanticExplanation: "高摩擦感和高警觉度更明显，常见于它不想被碰、想保持距离，或者正对环境刺激做防御。",
            semanticSuggestion: "先后退一点，给它留出退路和躲藏空间，暂时不要强行互动。",
            referenceSignature: CatAudioSignature(duration: 1.12, averageIntensity: 0.66, peakIntensity: 0.95, activityScore: 0.67, zeroCrossingRate: 0.72, silenceRatio: 0.07),
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
