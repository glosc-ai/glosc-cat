//
//  AppModels.swift
//  glosc-cat
//
//  Created by GitHub Copilot on 2026/3/21.
//

import Foundation
import SwiftData

enum AppMode: String, CaseIterable, Identifiable {
    case catToHuman
    case humanToCat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .catToHuman:
            return "猫语转人话"
        case .humanToCat:
            return "人话转猫语"
        }
    }

    var subtitle: String {
        switch self {
        case .catToHuman:
            return "录下来，看看它现在更像是在撒娇、求助，还是想互动。"
        case .humanToCat:
            return "把你的话变成更贴近猫咪节奏的喵语，温柔一点地回应它。"
        }
    }
}

enum CatTone: String, CaseIterable, Identifiable, Codable {
    case soothe
    case call
    case praise
    case play

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soothe:
            return "安抚"
        case .call:
            return "召唤"
        case .praise:
            return "夸奖"
        case .play:
            return "陪玩"
        }
    }

    var subtitle: String {
        switch self {
        case .soothe:
            return "轻一点，软一点"
        case .call:
            return "更明确地叫它"
        case .praise:
            return "像在夸它好乖"
        case .play:
            return "更活泼地邀请互动"
        }
    }
}

struct CatAudioSnapshot: Equatable {
    let duration: TimeInterval
    let averageIntensity: Double
    let peakIntensity: Double
    let activityScore: Double
    let zeroCrossingRate: Double
    let silenceRatio: Double
    let sourceLabel: String

    init(
        duration: TimeInterval,
        averageIntensity: Double,
        peakIntensity: Double,
        activityScore: Double,
        zeroCrossingRate: Double = 0.2,
        silenceRatio: Double = 0.2,
        sourceLabel: String
    ) {
        self.duration = duration
        self.averageIntensity = averageIntensity
        self.peakIntensity = peakIntensity
        self.activityScore = activityScore
        self.zeroCrossingRate = zeroCrossingRate
        self.silenceRatio = silenceRatio
        self.sourceLabel = sourceLabel
    }

    var signature: CatAudioSignature {
        CatAudioSignature(
            duration: duration,
            averageIntensity: averageIntensity,
            peakIntensity: peakIntensity,
            activityScore: activityScore,
            zeroCrossingRate: zeroCrossingRate,
            silenceRatio: silenceRatio
        )
    }
}

struct CatAudioSignature: Equatable {
    let duration: TimeInterval
    let averageIntensity: Double
    let peakIntensity: Double
    let activityScore: Double
    let zeroCrossingRate: Double
    let silenceRatio: Double

    func similarity(to other: CatAudioSignature) -> Double {
        let durationScale = max(max(duration, other.duration), 0.6)
        let durationDistance = min(abs(duration - other.duration) / durationScale, 1)
        let averageDistance = abs(averageIntensity - other.averageIntensity)
        let peakDistance = abs(peakIntensity - other.peakIntensity)
        let activityDistance = abs(activityScore - other.activityScore)
        let zeroCrossingDistance = abs(zeroCrossingRate - other.zeroCrossingRate)
        let silenceDistance = abs(silenceRatio - other.silenceRatio)

        let weightedDistance =
            (durationDistance * 0.2) +
            (averageDistance * 0.18) +
            (peakDistance * 0.18) +
            (activityDistance * 0.18) +
            (zeroCrossingDistance * 0.16) +
            (silenceDistance * 0.1)

        return max(0, 1 - weightedDistance)
    }
}

struct CatSemanticMatch: Equatable {
    let sampleID: String
    let sampleTitle: String
    let sampleIntent: String
    let similarity: Double
    let comparisonSummary: String
}

struct CatInterpretation: Equatable {
    let emotion: String
    let need: String
    let explanation: String
    let suggestion: String
    let confidenceNote: String
    let sourceLabel: String
    let matchedSample: CatSemanticMatch?
    let analysisSummary: String

    var shareText: String {
        let matchedText = matchedSample.map {
            " 最接近的真实样本是“\($0.sampleTitle)”，相似度约\(Int(($0.similarity * 100).rounded()))%。"
        } ?? ""
        return "说猫语帮我听到：\(emotion)｜\(need)。\(explanation)\(matchedText) 建议：\(suggestion)"
    }
}

struct CatPhrasePlan: Equatable {
    let originalText: String
    let tone: CatTone
    let catText: String
    let explanation: String
    let playbackText: String
    let sampleID: String
    let sampleTitle: String
    let sampleIntent: String

    var shareText: String {
        "我把“\(originalText)”翻成了猫语：\(catText)。这次匹配的是“\(sampleTitle)”猫叫样本，语气：\(tone.title)。"
    }
}

@Model
final class InteractionRecord {
    var id: UUID
    var createdAt: Date
    var modeRaw: String
    var title: String
    var summary: String
    var detail: String
    var accent: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        modeRaw: String,
        title: String,
        summary: String,
        detail: String,
        accent: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.modeRaw = modeRaw
        self.title = title
        self.summary = summary
        self.detail = detail
        self.accent = accent
    }

    var mode: AppMode {
        AppMode(rawValue: modeRaw) ?? .catToHuman
    }
}

@Model
final class FavoritePhrase {
    var id: UUID
    var createdAt: Date
    var originalText: String
    var toneRaw: String
    var catText: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        originalText: String,
        toneRaw: String,
        catText: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.originalText = originalText
        self.toneRaw = toneRaw
        self.catText = catText
    }

    var tone: CatTone {
        CatTone(rawValue: toneRaw) ?? .soothe
    }
}