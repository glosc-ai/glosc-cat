//
//  ContentView.swift
//  glosc-cat
//
//  Created by XiaoM on 2026/3/21.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageStore: LanguageStore
    @Query(sort: \InteractionRecord.createdAt, order: .reverse) private var records: [InteractionRecord]
    @Query(sort: \FavoritePhrase.createdAt, order: .reverse) private var favoritePhrases: [FavoritePhrase]

    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        modeSelector
                        activePanel

                        if let errorMessage = viewModel.errorMessage {
                            MessageBanner(
                                title: L10n.tr("banner.error.title"),
                                message: errorMessage,
                                accent: AppPalette.coral
                            )
                        }

                        MessageBanner(
                            title: L10n.tr("banner.status.title"),
                            message: viewModel.statusMessage,
                            accent: AppPalette.sage
                        )

                        heroSection
                        recentRecordsSection

                        if !favoritePhrases.isEmpty {
                            favoritesSection
                        }

                        gentleTipsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .fileImporter(
            isPresented: $viewModel.isImportingAudio,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false,
            onCompletion: { result in viewModel.handleImportedAudio(result, modelContext: modelContext) }
        )
        .onChange(of: viewModel.speechTranscriber.transcript) { _, newValue in
            viewModel.humanText = newValue
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppPalette.peach, AppPalette.cream, AppPalette.oat],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(AppPalette.white.opacity(0.65))
                        .frame(width: 110, height: 110)
                        .offset(x: 18, y: -22)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(AppPalette.coral.opacity(0.14))
                        .frame(width: 90, height: 90)
                        .offset(x: -18, y: 20)
                }

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "cat.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppPalette.ink)

                    Text(L10n.tr("hero.title"))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                        .accessibilityIdentifier("screen.title")

                    Spacer(minLength: 12)

                    Menu {
                        Button {
                            languageStore.resetToFollowSystem()
                        } label: {
                            Text(L10n.tr("language.selector.follow_system"))
                        }
                        .accessibilityIdentifier("language.selector.follow_system")

                        ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                            Button {
                                languageStore.setOverride(language)
                            } label: {
                                Text(language.displayName)
                            }
                            .accessibilityIdentifier("language.selector.option.\(language.rawValue)")
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.system(size: 12, weight: .semibold))

                            Text(languageStore.currentLanguage.displayName)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .lineLimit(1)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(AppPalette.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppPalette.white.opacity(0.92))
                        )
                    }
                    .accessibilityIdentifier("language.selector")
                    .accessibilityLabel(L10n.tr("language.selector.title"))
                }

                Text(L10n.tr("hero.subtitle"))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.ink.opacity(0.82))
                    .lineSpacing(3)

                HStack(spacing: 12) {
                    HighlightPill(icon: "waveform", text: L10n.tr("hero.pill.record"))
                    HighlightPill(icon: "text.bubble", text: L10n.tr("hero.pill.generate"))
                    HighlightPill(icon: "heart", text: L10n.tr("hero.pill.care"))
                }
            }
            .padding(24)
        }
        .shadow(color: AppPalette.shadow, radius: 22, x: 0, y: 16)
    }

    private var modeSelector: some View {
        HStack(spacing: 12) {
            ForEach(AppMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        if viewModel.selectedMode != mode, viewModel.speechTranscriber.isTranscribing {
                            viewModel.speechTranscriber.stop()
                        }
                        viewModel.selectedMode = mode
                        viewModel.errorMessage = nil
                        viewModel.statusMessage = mode.subtitle
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mode.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text(mode == .catToHuman ? L10n.tr("mode_selector.cat_to_human.caption") : L10n.tr("mode_selector.human_to_cat.caption"))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppPalette.ink.opacity(0.68))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(viewModel.selectedMode == mode ? AppPalette.white : AppPalette.white.opacity(0.78))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(viewModel.selectedMode == mode ? AppPalette.coral : AppPalette.white.opacity(0.2), lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(mode == .catToHuman ? "mode.catToHuman" : "mode.humanToCat")
            }
        }
    }

    @ViewBuilder
    private var activePanel: some View {
        switch viewModel.selectedMode {
        case .catToHuman:
            catToHumanPanel
        case .humanToCat:
            humanToCatPanel
        }
    }

    private var catToHumanPanel: some View {
        VStack(spacing: 18) {
            SectionCard(title: L10n.tr("panel.cat_to_human.title"), subtitle: viewModel.latestInterpretation == nil ? L10n.tr("panel.cat_to_human.subtitle.empty") : L10n.tr("panel.cat_to_human.subtitle.result")) {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(AppPalette.peach.opacity(0.22))
                            .frame(width: 190, height: 190)
                            .scaleEffect(viewModel.recorder.isRecording ? 1.02 + viewModel.recorder.liveLevel * 0.28 : 1.0)

                        Circle()
                            .fill(AppPalette.white)
                            .frame(width: 150, height: 150)
                            .shadow(color: AppPalette.shadow, radius: 20, x: 0, y: 16)

                        Button {
                            viewModel.toggleRecording(modelContext: modelContext)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: viewModel.recorder.isRecording ? "pause.fill" : "mic.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                Text(viewModel.recorder.isRecording ? L10n.tr("record.button.stop") : L10n.tr("record.button.start"))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(AppPalette.ink)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("record.toggle")
                    }
                    .animation(.easeInOut(duration: 0.35), value: viewModel.recorder.isRecording)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.recorder.liveLevel)

                    Text(viewModel.recorder.isRecording ? L10n.tr("record.helper.recording") : L10n.tr("record.helper.idle"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.72))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        ActionButton(
                            title: viewModel.isAnalyzingAudio ? L10n.tr("action.analyzing") : L10n.tr("action.import_audio"),
                            subtitle: L10n.tr("action.import_audio.subtitle"),
                            systemImage: "square.and.arrow.down",
                            fill: AppPalette.white,
                            foreground: AppPalette.ink,
                            bordered: true,
                            action: { viewModel.isImportingAudio = true }
                        )
                        .disabled(viewModel.recorder.isRecording || viewModel.isAnalyzingAudio)
                        .accessibilityIdentifier("analyze.import")

                        ActionButton(
                            title: viewModel.recorder.isRecording ? L10n.tr("action.finish_recording") : L10n.tr("action.analyze_builtin_sample"),
                            subtitle: viewModel.recorder.isRecording ? L10n.tr("action.finish_recording.subtitle") : L10n.tr("action.analyze_builtin_sample.subtitle"),
                            systemImage: viewModel.recorder.isRecording ? "sparkles" : "wand.and.stars",
                            fill: AppPalette.coral,
                            foreground: AppPalette.white,
                            bordered: false,
                            action: {
                                if viewModel.recorder.isRecording {
                                    viewModel.stopRecordingAndAnalyze(modelContext: modelContext)
                                } else {
                                    viewModel.analyzeDemoClip(modelContext: modelContext)
                                }
                            }
                        )
                        .disabled(viewModel.isAnalyzingAudio)
                    }

                    if viewModel.isAnalyzingAudio {
                        analysisInPlaceSection
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.96)), removal: .opacity))
                    } else if let latestInterpretation = viewModel.latestInterpretation {
                        integratedResultSection(interpretation: latestInterpretation)
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.94)), removal: .opacity))
                    }
                }
            }

            sampleLibrarySection
        }
    }

    private var analysisInPlaceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                AnalysisPulseView()

                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.tr("analysis.in_place.title"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                    Text(L10n.tr("analysis.in_place.subtitle"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.68))
                        .lineSpacing(2)
                }

                Spacer(minLength: 0)
            }

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppPalette.peach.opacity(0.22), AppPalette.white, AppPalette.cream.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 78)
                .overlay {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { index in
                                Capsule(style: .continuous)
                                    .fill(index.isMultiple(of: 2) ? AppPalette.coral.opacity(0.8) : AppPalette.sage.opacity(0.75))
                                    .frame(width: 8, height: CGFloat([18, 30, 22, 34, 16][index]))
                            }
                        }

                        Text(L10n.tr("analysis.in_place.footer"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.ink.opacity(0.62))
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppPalette.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppPalette.peach.opacity(0.9), lineWidth: 1)
        )
    }

    private var humanToCatPanel: some View {
        VStack(spacing: 18) {
            SectionCard(title: L10n.tr("panel.human_to_cat.title"), subtitle: L10n.tr("panel.human_to_cat.subtitle")) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.tr("input.title"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppPalette.ink.opacity(0.76))

                        VStack(alignment: .leading, spacing: 12) {
                            TextField(L10n.tr("input.placeholder"), text: $viewModel.humanText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3, reservesSpace: true)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .accessibilityIdentifier("textInput.human")

                            Button {
                                viewModel.toggleSpeechTranscription()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: viewModel.speechTranscriber.isTranscribing ? "waveform.circle.fill" : "mic.circle")
                                        .font(.system(size: 20, weight: .semibold))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(viewModel.speechTranscriber.isTranscribing ? L10n.tr("speech.button.stop") : L10n.tr("speech.button.start"))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                        Text(viewModel.speechTranscriber.isTranscribing ? L10n.tr("speech.button.stop.subtitle") : L10n.tr("speech.button.start.subtitle"))
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(AppPalette.ink.opacity(0.66))
                                    }

                                    Spacer()
                                }
                                .foregroundStyle(AppPalette.ink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(viewModel.speechTranscriber.isTranscribing ? AppPalette.peach.opacity(0.8) : AppPalette.oat.opacity(0.45))
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("speechToText.toggle")
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppPalette.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppPalette.oat, lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.tr("tone.section.title"))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppPalette.ink.opacity(0.76))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(CatTone.allCases) { tone in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                                        viewModel.selectedTone = tone
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(tone.title)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(AppPalette.ink)
                                        Text(tone.subtitle)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(AppPalette.ink.opacity(0.68))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(viewModel.selectedTone == tone ? AppPalette.peach.opacity(0.6) : AppPalette.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(viewModel.selectedTone == tone ? AppPalette.coral : AppPalette.oat, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    ActionButton(
                        title: L10n.tr("generate.button.title"),
                        subtitle: L10n.tr("generate.button.subtitle"),
                        systemImage: "sparkles.rectangle.stack",
                        fill: AppPalette.coral,
                        foreground: AppPalette.white,
                        bordered: false,
                        action: { viewModel.generatePhrase(modelContext: modelContext) }
                    )
                    .accessibilityIdentifier("generate.catPhrase")
                }
            }

            if let generatedPhrase = viewModel.generatedPhrase {
                generatedPhraseSection(plan: generatedPhrase)
            }
        }
    }

    private func integratedResultSection(interpretation: CatInterpretation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.tr("result.title"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.62))
                    Text(interpretation.emotion)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                        .accessibilityIdentifier("result.emotion")
                    Text(interpretation.sourceLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.58))
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(L10n.tr("result.need.title"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.55))
                    Text(interpretation.need)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppPalette.sage.opacity(0.22))
                        )
                }
            }

            InterpretationShowcase(interpretation: interpretation)
            DetailCard(title: L10n.tr("result.analysis.title"), text: interpretation.analysisSummary)

            if let matchedSample = interpretation.matchedSample {
                DetailCard(
                    title: L10n.tr("result.sample_match.title"),
                    text: L10n.format(
                        "result.sample_match.text",
                        matchedSample.sampleTitle,
                        matchedSample.sampleIntent,
                        Int((matchedSample.similarity * 100).rounded()),
                        matchedSample.comparisonSummary
                    )
                )
            }

            HStack(spacing: 12) {
                ShareLink(item: interpretation.shareText) {
                    Label(L10n.tr("share.result.button"), systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppPalette.white)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.analyzeDemoClip(modelContext: modelContext)
                } label: {
                    Label(L10n.tr("retry.button"), systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppPalette.peach.opacity(0.65))
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppPalette.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppPalette.white, AppPalette.card, AppPalette.peach.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppPalette.white.opacity(0.94), lineWidth: 1.2)
        )
        .shadow(color: AppPalette.shadow.opacity(0.7), radius: 14, x: 0, y: 10)
    }

    private func generatedPhraseSection(plan: CatPhrasePlan) -> some View {
        SectionCard(title: L10n.tr("generated.section.title"), subtitle: L10n.format("generated.section.subtitle", plan.originalText)) {
            VStack(alignment: .leading, spacing: 14) {
                Text(plan.catText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.ink)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppPalette.peach.opacity(0.35))
                    )

                DetailCard(title: L10n.tr("generated.tone_explanation.title"), text: plan.explanation)
                DetailCard(title: L10n.tr("generated.sample.title"), text: L10n.format("generated.sample.text", plan.sampleTitle, plan.sampleIntent))

                HStack(spacing: 12) {
                    ActionButton(
                        title: viewModel.samplePlayer.currentSampleID == plan.sampleID && viewModel.samplePlayer.isPlaying ? L10n.tr("generated.playing.button") : L10n.tr("generated.play.button"),
                        subtitle: L10n.tr("generated.play.button.subtitle"),
                        systemImage: viewModel.samplePlayer.currentSampleID == plan.sampleID && viewModel.samplePlayer.isPlaying ? "speaker.wave.3.fill" : "play.fill",
                        fill: AppPalette.coral,
                        foreground: AppPalette.white,
                        bordered: false,
                        action: { viewModel.playMatchedSample(for: plan) }
                    )

                    ActionButton(
                        title: viewModel.isFavorite(plan, favoritePhrases: favoritePhrases) ? L10n.tr("favorite.button.saved") : L10n.tr("favorite.button.save"),
                        subtitle: L10n.tr("favorite.button.subtitle"),
                        systemImage: viewModel.isFavorite(plan, favoritePhrases: favoritePhrases) ? "heart.fill" : "heart",
                        fill: AppPalette.white,
                        foreground: AppPalette.ink,
                        bordered: true,
                        action: { viewModel.toggleFavorite(for: plan, favoritePhrases: favoritePhrases, modelContext: modelContext) }
                    )
                }

                ShareLink(item: plan.shareText) {
                    Label(L10n.tr("share.phrase.button"), systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppPalette.white)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppPalette.ink)
            }
        }
    }

    private var sampleLibrarySection: some View {
        SectionCard(title: L10n.tr("sample_library.title"), subtitle: L10n.tr("sample_library.subtitle")) {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CatAudioSample.builtIn) { sample in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(sample.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.ink)

                                Text(sample.intent)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.coral)

                                Text(sample.detail)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppPalette.ink.opacity(0.72))
                                    .lineSpacing(2)
                                    .lineLimit(3)

                                Text(sample.license)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.ink.opacity(0.7))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(AppPalette.peach.opacity(0.45))
                                    )

                                HStack(spacing: 8) {
                                    Button {
                                        viewModel.playSample(sample)
                                    } label: {
                                        Label(
                                            viewModel.samplePlayer.currentSampleID == sample.id && viewModel.samplePlayer.isPlaying ? L10n.tr("sample_library.stop") : L10n.tr("sample_library.preview"),
                                            systemImage: viewModel.samplePlayer.currentSampleID == sample.id && viewModel.samplePlayer.isPlaying ? "stop.fill" : "play.fill"
                                        )
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(AppPalette.white)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(AppPalette.ink)

                                    Button {
                                        viewModel.analyzeBundledSample(sample, modelContext: modelContext)
                                    } label: {
                                        Label(L10n.tr("sample_library.analyze"), systemImage: "waveform.path.ecg")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(AppPalette.coral)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(AppPalette.white)
                                }
                            }
                            .frame(width: 240, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(AppPalette.white)
                            )
                        }
                    }
                }

                Text(L10n.tr("sample_library.footer"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.ink.opacity(0.6))
                    .lineSpacing(2)
            }
        }
    }

    private var recentRecordsSection: some View {
        SectionCard(title: L10n.tr("recent.title"), subtitle: records.isEmpty ? L10n.tr("recent.subtitle.empty") : L10n.tr("recent.subtitle.filled")) {
            if records.isEmpty {
                DetailCard(
                    title: L10n.tr("recent.empty.title"),
                    text: L10n.tr("recent.empty.text")
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(records.prefix(3))) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(record.mode.title)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.coral)
                                Spacer()
                                Text(record.createdAt, style: .time)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppPalette.ink.opacity(0.5))
                            }

                            Text(record.title)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.ink)

                            Text(record.summary)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppPalette.ink.opacity(0.72))

                            Text(record.detail)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppPalette.ink.opacity(0.64))
                                .lineSpacing(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppPalette.white)
                        )
                    }
                }
            }
        }
    }

    private var favoritesSection: some View {
        SectionCard(title: L10n.tr("favorites.title"), subtitle: L10n.tr("favorites.subtitle")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(favoritePhrases.prefix(6))) { favorite in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(favorite.tone.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.coral)

                            Text(favorite.originalText)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.ink)
                                .lineLimit(2)

                            Text(favorite.catText)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppPalette.ink.opacity(0.66))
                                .lineLimit(2)
                        }
                        .frame(width: 190, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppPalette.white)
                        )
                    }
                }
            }
        }
        .accessibilityIdentifier("favorites.section")
    }

    private var gentleTipsSection: some View {
        SectionCard(title: L10n.tr("tips.title"), subtitle: L10n.tr("tips.subtitle")) {
            VStack(alignment: .leading, spacing: 10) {
                TipRow(text: L10n.tr("tips.item1"))
                TipRow(text: L10n.tr("tips.item2"))
                TipRow(text: L10n.tr("tips.item3"))
            }
        }
    }

}

#Preview {
    ContentView()
        .environmentObject(LanguageStore())
        .modelContainer(for: [InteractionRecord.self, FavoritePhrase.self], inMemory: true)
}
