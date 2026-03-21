//
//  glosc_catTests.swift
//  glosc-catTests
//
//  Created by XiaoM on 2026/3/21.
//

import Testing
@testable import glosc_cat

struct glosc_catTests {

    @Test func quietLongMeowLooksAffectionate() async throws {
        let snapshot = CatAudioSnapshot(
            duration: 3.1,
            averageIntensity: 0.12,
            peakIntensity: 0.24,
            activityScore: 0.18,
            sourceLabel: "测试录音"
        )

        let result = CatAudioAnalyzer.interpret(snapshot)

        #expect(result.emotion == "想撒娇")
        #expect(result.need == "想靠近你或要一点陪伴")
    }

    @Test func shortLoudMeowLooksUrgent() async throws {
        let snapshot = CatAudioSnapshot(
            duration: 0.7,
            averageIntensity: 0.68,
            peakIntensity: 0.88,
            activityScore: 0.62,
            sourceLabel: "测试录音"
        )

        let result = CatAudioAnalyzer.interpret(snapshot)

        #expect(result.emotion == "有点急切")
        #expect(result.confidenceNote == "更像提醒型叫声")
    }

    @Test func phraseComposerKeepsOriginalMeaningAndTone() async throws {
        let plan = CatPhraseComposer.generate(text: "来吃饭啦，不要挑食", tone: .call)

        #expect(plan.originalText == "来吃饭啦，不要挑食")
        #expect(plan.tone == .call)
        #expect(plan.catText.contains("喵"))
        #expect(plan.explanation.contains("温柔地叫它过来"))
        #expect(plan.sampleTitle == "想吃东西")
        #expect(plan.sampleIntent == "饭点提醒")
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

        #expect(playSample.id == "impatient_outside")
        #expect(foodSample.id == "food_request")
    }
}
