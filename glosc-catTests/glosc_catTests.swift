//
//  glosc_catTests.swift
//  glosc-catTests
//
//  Created by XiaoM on 2026/3/21.
//

import Foundation
import Testing
@testable import glosc_cat

@MainActor
@Suite(.serialized)
struct glosc_catTests {

    private let languageOverrideKey = "app.language.override"

    @Test func quietLongMeowProducesReadableAnalysis() async throws {
        let snapshot = CatAudioSnapshot(
            duration: 3.1,
            averageIntensity: 0.12,
            peakIntensity: 0.24,
            activityScore: 0.18,
            zeroCrossingRate: 0.09,
            silenceRatio: 0.33,
            sourceLabel: "测试录音"
        )

        let result = CatAudioAnalyzer.interpret(snapshot)

        #expect(!result.emotion.isEmpty)
        #expect(!result.need.isEmpty)
        #expect(!result.suggestion.isEmpty)
        #expect(!result.analysisSummary.isEmpty)
    }

    @Test func shortLoudMeowProducesReadableAnalysis() async throws {
        let snapshot = CatAudioSnapshot(
            duration: 0.7,
            averageIntensity: 0.68,
            peakIntensity: 0.88,
            activityScore: 0.62,
            zeroCrossingRate: 0.34,
            silenceRatio: 0.12,
            sourceLabel: "测试录音"
        )

        let result = CatAudioAnalyzer.interpret(snapshot)

        #expect(!result.emotion.isEmpty)
        #expect(!result.explanation.isEmpty)
        #expect(!result.confidenceNote.isEmpty)
    }

    @Test func audioSignatureSimilarityPrefersCloserReference() async throws {
        let candidate = CatAudioSignature(
            duration: 1.04,
            averageIntensity: 0.56,
            peakIntensity: 0.81,
            activityScore: 0.43,
            zeroCrossingRate: 0.29,
            silenceRatio: 0.15
        )
        let hungryReference = try #require(CatAudioSample.builtIn.first(where: { $0.id == "hungry_now" }))
        let affectionateReference = try #require(CatAudioSample.builtIn.first(where: { $0.id == "like_you" }))

        #expect(candidate.similarity(to: hungryReference.referenceSignature) > candidate.similarity(to: affectionateReference.referenceSignature))
    }

    @Test func phraseComposerKeepsOriginalMeaningAndTone() async throws {
        let plan = CatPhraseComposer.generate(text: "来吃饭啦，不要挑食", tone: .call)

        #expect(plan.originalText == "来吃饭啦，不要挑食")
        #expect(plan.tone == .call)
        #expect(!plan.catText.isEmpty)
        #expect(!plan.explanation.isEmpty)
        #expect(plan.sampleID == "meal_time")
        #expect(!plan.sampleTitle.isEmpty)
        #expect(!plan.sampleIntent.isEmpty)
    }

    @Test func builtInSamplesCoverTonePreview() async throws {
        #expect(CatAudioSample.builtIn.count >= 4)

        for tone in CatTone.allCases {
            let sample = CatAudioSample.demoSample(for: tone)

            #expect(sample.canPlayInApp)
            #expect(sample.recommendedTone != nil)
        }
    }

    @Test func sampleMatcherPrefersKeywordIntent() async throws {
        let playSample = CatAudioSample.bestMatch(for: "快来陪我玩一会儿", tone: .play)
        let foodSample = CatAudioSample.bestMatch(for: "来吃饭啦", tone: .call)

        #expect(playSample.id == "play_together")
        #expect(foodSample.id == "meal_time")
    }

    @Test func languageOverrideChangesLocalizedHeroTitle() async throws {
        UserDefaults.standard.removeObject(forKey: languageOverrideKey)
        defer { UserDefaults.standard.removeObject(forKey: languageOverrideKey) }

        AppLocalizationSupport.setOverrideLanguage(.english)

        #expect(AppLocalizationSupport.overrideLanguage == .english)
        #expect(L10n.tr("hero.title") == "Glosc Cat")
    }

    @Test func clearingLanguageOverrideReturnsToFollowSystem() async throws {
        UserDefaults.standard.removeObject(forKey: languageOverrideKey)
        defer { UserDefaults.standard.removeObject(forKey: languageOverrideKey) }

        AppLocalizationSupport.setOverrideLanguage(.simplifiedChinese)
        #expect(AppLocalizationSupport.overrideLanguage == .simplifiedChinese)

        AppLocalizationSupport.setOverrideLanguage(nil)

        #expect(AppLocalizationSupport.overrideLanguage == nil)
        #expect(AppLocalizationSupport.isFollowingSystem)
    }

    @Test func chineseOverrideKeepsChineseHeroTitle() async throws {
        UserDefaults.standard.removeObject(forKey: languageOverrideKey)
        defer { UserDefaults.standard.removeObject(forKey: languageOverrideKey) }

        AppLocalizationSupport.setOverrideLanguage(.simplifiedChinese)

        #expect(L10n.tr("hero.title") == "说猫语")
    }
}
