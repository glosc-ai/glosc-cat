import Combine
import Foundation

nonisolated enum AppLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case spanish = "es"
    case hindi = "hi"
    case arabic = "ar"
    case portugueseBrazil = "pt-BR"
    case russian = "ru"
    case japanese = "ja"
    case french = "fr"
    case german = "de"

    init(identifier: String) {
        let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()

        switch true {
        case normalized.hasPrefix("zh"):
            self = .simplifiedChinese
        case normalized.hasPrefix("es"):
            self = .spanish
        case normalized.hasPrefix("hi"):
            self = .hindi
        case normalized.hasPrefix("ar"):
            self = .arabic
        case normalized.hasPrefix("pt"):
            self = .portugueseBrazil
        case normalized.hasPrefix("ru"):
            self = .russian
        case normalized.hasPrefix("ja"):
            self = .japanese
        case normalized.hasPrefix("fr"):
            self = .french
        case normalized.hasPrefix("de"):
            self = .german
        default:
            self = .english
        }
    }

    var localeIdentifier: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "中文简体"
        case .spanish:
            return "Español"
        case .hindi:
            return "हिन्दी"
        case .arabic:
            return "العربية"
        case .portugueseBrazil:
            return "Português (Brasil)"
        case .russian:
            return "Русский"
        case .japanese:
            return "日本語"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        }
    }

    var speechRecognizerLocaleIdentifier: String {
        switch self {
        case .english:
            return "en-US"
        case .simplifiedChinese:
            return "zh-CN"
        case .spanish:
            return "es-ES"
        case .hindi:
            return "hi-IN"
        case .arabic:
            return "ar-SA"
        case .portugueseBrazil:
            return "pt-BR"
        case .russian:
            return "ru-RU"
        case .japanese:
            return "ja-JP"
        case .french:
            return "fr-FR"
        case .german:
            return "de-DE"
        }
    }
}

nonisolated enum AppLocalizationSupport {
    static let overrideLanguageDefaultsKey = "app.language.override"
    static let followSystemOverrideValue = "system"

    static func prepareForLaunch() {
        if ProcessInfo.processInfo.arguments.contains("UITestResetLanguageOverride") {
            UserDefaults.standard.removeObject(forKey: overrideLanguageDefaultsKey)
        }
    }

    static var systemLanguage: AppLanguage {
        let preferredIdentifier = Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? AppLanguage.english.rawValue

        return AppLanguage(identifier: preferredIdentifier)
    }

    static var overrideLanguage: AppLanguage? {
        guard let rawValue = UserDefaults.standard.string(forKey: overrideLanguageDefaultsKey),
              rawValue != followSystemOverrideValue,
              !rawValue.isEmpty else {
            return nil
        }

        return AppLanguage(identifier: rawValue)
    }

    static var isFollowingSystem: Bool {
        overrideLanguage == nil
    }

    static func setOverrideLanguage(_ language: AppLanguage?) {
        if let language {
            UserDefaults.standard.set(language.rawValue, forKey: overrideLanguageDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: overrideLanguageDefaultsKey)
        }
    }

    static var currentLanguage: AppLanguage {
        overrideLanguage ?? systemLanguage
    }

    static var formattingLocale: Locale {
        Locale(identifier: currentLanguage.localeIdentifier)
    }

    static var speechLocale: Locale {
        Locale(identifier: currentLanguage.speechRecognizerLocaleIdentifier)
    }

    static var speechVoiceLanguageCode: String {
        currentLanguage.speechRecognizerLocaleIdentifier
    }
}

nonisolated enum L10n {
    static func tr(_ key: String) -> String {
        AppStrings.value(for: key, language: AppLocalizationSupport.currentLanguage)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: AppLocalizationSupport.formattingLocale, arguments: arguments)
    }
}

@MainActor
final class LanguageStore: ObservableObject {
    @Published private(set) var currentLanguage: AppLanguage = AppLocalizationSupport.currentLanguage

    var isFollowingSystem: Bool {
        AppLocalizationSupport.isFollowingSystem
    }

    func setOverride(_ language: AppLanguage?) {
        AppLocalizationSupport.setOverrideLanguage(language)
        currentLanguage = AppLocalizationSupport.currentLanguage
    }

    func resetToFollowSystem() {
        setOverride(nil)
    }
}

nonisolated private enum AppStrings {
    private static let english: [String: String] = [
        "app.mode.cat_to_human.title": "Cat to Human",
        "app.mode.human_to_cat.title": "Human to Cat",
        "language.selector.title": "Language",
        "language.selector.subtitle": "Choose how the app speaks with you",
        "language.selector.follow_system": "Follow system",
        "app.mode.cat_to_human.subtitle": "Record it and see whether your cat sounds cuddly, needy, or ready to interact.",
        "app.mode.human_to_cat.subtitle": "Turn your words into cat-like rhythm and answer gently.",
        "tone.soothe.title": "Soothe",
        "tone.call.title": "Call",
        "tone.praise.title": "Praise",
        "tone.play.title": "Play",
        "tone.soothe.subtitle": "Softer and gentler",
        "tone.call.subtitle": "Call more clearly",
        "tone.praise.subtitle": "Like telling your cat it did great",
        "tone.play.subtitle": "Invite interaction more playfully",
        "share.interpretation.matched_sample": " The closest real sample is \"%@\", with about %d%% similarity.",
        "share.interpretation.full": "Glosc Cat heard this for me: %@ | %@. %@%@ Suggestion: %@",
        "share.phrase.full": "I translated \"%@\" into cat language: %@. This time it matched the real cat sample \"%@\", tone: %@.",
        "banner.error.title": "This time it didn’t finish smoothly",
        "banner.status.title": "Current status",
        "privacy.banner.title": "Privacy settings",
        "privacy.options.button": "Privacy options",
        "privacy.options.error": "The privacy options page could not be opened right now. Try again in a moment.",
        "privacy.consent.error": "The privacy consent message could not be prepared right now. If consent is not required for this device, ads may still continue with the previous state.",
        "launch.overlay.title": "Glosc Cat is getting ready",
        "launch.overlay.subtitle": "Keeping a soft little waiting moment for you, and preparing the app-open ad when it is ready.",
        "hero.title": "Glosc Cat",
        "hero.subtitle": "Turn not understanding and not knowing how to respond into soft, easy, adorable daily moments.",
        "hero.pill.record": "Record analysis",
        "hero.pill.generate": "Cat phrase",
        "hero.pill.care": "Care tips",
        "mode_selector.cat_to_human.caption": "Understand feelings and needs",
        "mode_selector.human_to_cat.caption": "Turn your words into cat rhythm",
        "panel.cat_to_human.title": "Cat to Human",
        "panel.cat_to_human.subtitle.empty": "Record or import audio and I’ll give you a gentle, practical read first.",
        "panel.cat_to_human.subtitle.result": "Actions and results stay together so you can see what this sound most likely means right away.",
        "record.button.stop": "Stop listening",
        "record.button.start": "Start recording",
        "record.helper.recording": "Keep going, I’m listening to the mood and rhythm in this sound.",
        "record.helper.idle": "You can record a meow directly or import audio you already have.",
        "action.analyzing": "Analyzing",
        "action.import_audio": "Import audio",
        "action.import_audio.subtitle": "Local audio works too",
        "action.finish_recording": "Finish this recording",
        "action.finish_recording.subtitle": "I’ll show you the result right away",
        "action.analyze_builtin_sample": "Analyze built-in sample",
        "action.analyze_builtin_sample.subtitle": "See how a real sample is judged",
        "analysis.in_place.title": "Listening through this cat phrase for you",
        "analysis.in_place.subtitle": "I’m comparing it with real local samples first, then using duration, loudness, and rhythm to turn it into something easier to understand.",
        "analysis.in_place.footer": "The result will expand here as soon as analysis finishes",
        "panel.human_to_cat.title": "Human to Cat",
        "panel.human_to_cat.subtitle": "Type what you want to say, pick a tone, and I’ll turn it into a more cat-like rhythm.",
        "input.title": "What do you want to say?",
        "input.placeholder": "For example: come eat, don’t be scared, I’m here",
        "speech.button.stop": "Stop talking and fill the box",
        "speech.button.start": "Speech to text",
        "speech.button.stop.subtitle": "I’m listening and typing — tap again when you’re done",
        "speech.button.start.subtitle": "Say it out loud if you don’t want to type",
        "tone.section.title": "Tone template",
        "generate.button.title": "Generate cat phrase",
        "generate.button.subtitle": "Keep the meaning, switch to a more cat-like rhythm",
        "result.title": "This one sounds more like",
        "result.need.title": "Main need",
        "result.analysis.title": "How this was judged",
        "result.sample_match.title": "Closest real sample",
        "result.sample_match.text": "%@ · %@. Current similarity is about %d%%. %@",
        "share.result.button": "Share result",
        "retry.button": "Try again",
        "generated.section.title": "Your cat-language version",
        "generated.section.subtitle": "Original: %@",
        "generated.tone_explanation.title": "Tone note",
        "generated.sample.title": "Cat sample to play",
        "generated.sample.text": "%@ · %@. This now plays the real cat sample directly instead of a stiff AI voice.",
        "generated.playing.button": "Playing cat sound",
        "generated.play.button": "Play matching cat sound",
        "generated.play.button.subtitle": "Play the matched real cat audio directly",
        "favorite.button.saved": "Saved",
        "favorite.button.save": "Save phrase",
        "favorite.button.subtitle": "Find frequent lines faster next time",
        "share.phrase.button": "Share this cat phrase",
        "sample_library.title": "Built-in cat samples",
        "sample_library.subtitle": "These real samples can be previewed directly and also act as the local semantic comparison library.",
        "sample_library.stop": "Stop",
        "sample_library.preview": "Preview",
        "sample_library.analyze": "Analyze",
        "sample_library.footer": "The app currently prioritizes mp3 and wav samples for preview and recognition; other ogg assets stay in the repo until unified transcoding is done.",
        "recent.title": "Recent interactions",
        "recent.subtitle.empty": "No records yet — once you analyze or generate something, it will show up here.",
        "recent.subtitle.filled": "Your recent conversations stay together here so they’re easier to revisit.",
        "recent.empty.title": "Still empty right now",
        "recent.empty.text": "Try one recording analysis or translate a common sentence into cat language, and this space will start to remember things.",
        "favorites.title": "Favorite phrases",
        "favorites.subtitle": "Keep your frequent lines here so you don’t need to type them again.",
        "tips.title": "Gentle tips",
        "tips.subtitle": "The result helps you understand your cat faster, but it doesn’t replace ongoing observation.",
        "tips.item1": "If the meow is repeatedly high and urgent, check food, water, litter, and doors or windows first.",
        "tips.item2": "If the sound is longer and softer, a gentle response usually works better than immediately teasing your cat.",
        "tips.item3": "Human-to-cat phrases work best for companionship and aren’t ideal for long continuous playback.",
        "status.idle": "Pick a direction first — I’ll keep the main actions close at hand.",
        "status.recording.listening": "I’m listening carefully to what your cat is saying.",
        "status.recording.start_failed": "This time recording couldn’t start.",
        "status.recording.stop_failed": "Something small went wrong when the recording ended.",
        "error.import.analysis_failed": "This audio couldn’t be analyzed smoothly right now. Try a clearer meow clip.",
        "status.import.failed": "There was a small issue while importing audio.",
        "error.import.no_file_selected": "No audio file was selected, so I’ll skip analysis this time.",
        "status.analysis.running": "I’m sorting out what this one sounds more like.",
        "error.sample.missing_in_bundle": "This built-in sample wasn’t found. Check whether it’s included in the app bundle.",
        "status.sample.unavailable": "The built-in sample isn’t available right now.",
        "error.sample.analysis_failed": "This built-in sample couldn’t be analyzed right now — try another one first.",
        "status.sample.analysis_failed": "Sample analysis failed.",
        "status.sample.stopped": "That cat sound has been stopped.",
        "status.sample.previewing": "Previewing the \"%@\" sample.",
        "status.sample.playback_failed": "The real cat sound couldn’t play smoothly.",
        "status.transcription.empty": "I still haven’t heard a clear human phrase this time.",
        "status.transcription.completed": "I’ve written it into the text box, so you can generate the cat phrase now.",
        "status.transcription.listening": "I’m listening to you now and will write directly into the text box.",
        "status.transcription.start_failed": "Speech-to-text couldn’t start smoothly this time.",
        "error.phrase.empty_input": "Type what you want to say first, then I can turn it into cat language.",
        "status.phrase.missing_input": "Still missing the original line.",
        "status.phrase.generated": "I’ve matched the real cat sample for you and will play it directly now.",
        "error.phrase.sample_missing": "This cat phrase doesn’t have a playable real sample yet.",
        "status.phrase.sample_unavailable": "The matching sample isn’t available right now.",
        "status.phrase.playing_sample": "Playing the real cat sound \"%@\".",
        "record.interpretation.detail": "%@ Suggestion: %@",
        "record.phrase.summary": "Tone: %@",
        "status.favorite.removed": "I’ve taken this one back out of favorites.",
        "status.favorite.added": "This line has been saved into your common phrases.",
        "analysis.match.explanation": "This recording is closest to the built-in real sample \"%@\", with about %d%% similarity. %@ %@",
        "analysis.match.summary": "This time I compared the recording against each local real cat sample first, then used duration, loudness, pauses, and rhythm changes to organize the meaning.",
        "analysis.heuristic.partial_match.summary": "This recording is somewhat similar to \"%@\", but not close enough, so this time the result mainly comes from the recording’s own duration, loudness, and rhythm.",
        "analysis.heuristic.no_match.summary": "No close enough local sample was found this time, so the result mainly comes from the recording’s own duration, loudness, and rhythm changes.",
        "heuristic.urgent.emotion": "A little urgent",
        "heuristic.urgent.need": "Wants an immediate response",
        "heuristic.urgent.explanation": "This sound is short but has a stronger peak, like a quick reminder to notice your cat — often around mealtime, a blocked door, or a need for attention right away.",
        "heuristic.urgent.suggestion": "Check whether your cat is near the food bowl, the door, or a favorite toy spot, then answer softly.",
        "heuristic.urgent.confidence": "Sample similarity is average; this sounds more like a reminder-type meow",
        "heuristic.affectionate.emotion": "Wants affection",
        "heuristic.affectionate.need": "Wants to be close or get a little company",
        "heuristic.affectionate.explanation": "This sound is longer and lighter overall, more like relaxed clingy affection than tension or resistance.",
        "heuristic.affectionate.suggestion": "Try crouching down to talk, or gently touch the chin area and see whether your cat comes closer.",
        "heuristic.affectionate.confidence": "Sample similarity is average; this sounds more like an affectionate meow",
        "heuristic.uneasy.emotion": "A little uneasy",
        "heuristic.uneasy.need": "Wants to confirm the environment feels safe",
        "heuristic.uneasy.explanation": "The sound changes quickly and rises and falls more strongly, which suggests your cat is more sensitive to the surroundings right now.",
        "heuristic.uneasy.suggestion": "Help make the space quieter first, then watch the ears and tail before getting too close too quickly.",
        "heuristic.uneasy.confidence": "Sample similarity is average; this feels more triggered by environmental stimulation",
        "heuristic.inviting.emotion": "Wants interaction",
        "heuristic.inviting.need": "Hopes you’ll notice or play for a bit",
        "heuristic.inviting.explanation": "This sound is fairly balanced in both length and loudness, like a steady invitation to interact rather than a complaint or a strong stress signal.",
        "heuristic.inviting.suggestion": "See whether your cat is guiding you toward a toy, the window, or a favorite spot, then answer in the same rhythm.",
        "heuristic.inviting.confidence": "Sample similarity is average; this sounds more like an invitation-type meow",
        "heuristic.gentle.emotion": "Gently testing",
        "heuristic.gentle.need": "Wants to know whether you’re listening",
        "heuristic.gentle.explanation": "The overall volume is low and the rhythm isn’t urgent, so this feels more like an everyday little reminder than a strong demand.",
        "heuristic.gentle.suggestion": "Call your cat’s name and answer a little more slowly, then watch whether your cat comes closer or leads you somewhere.",
        "heuristic.gentle.confidence": "Sample similarity is average; this sounds more like everyday communication",
        "analysis.dimension.duration": "duration",
        "analysis.dimension.average_intensity": "average loudness",
        "analysis.dimension.peak_intensity": "peak intensity",
        "analysis.dimension.rhythm": "rhythm change",
        "analysis.dimension.texture": "high-frequency texture",
        "analysis.dimension.pause_ratio": "pause ratio",
        "analysis.dimension.separator": ", ",
        "analysis.comparison.summary": "It’s closer to the \"%@\" sample in %@.",
        "analysis.confidence.high": "Very close to a local real sample",
        "analysis.confidence.medium": "Fairly close to a local real sample",
        "analysis.confidence.low": "Has some similarity to a local real sample",
        "error.audio.too_short": "This audio is too short — not enough to analyze yet.",
        "error.audio.conversion_failed": "This audio couldn’t be converted into analyzable data right now.",
        "catphrase.soothe.unit1": "mii-woo",
        "catphrase.soothe.unit2": "purr",
        "catphrase.soothe.unit3": "meow-woo",
        "catphrase.soothe.explanation": "This one feels softer and lighter at the end, good for comforting, bedtime company, or when your cat seems a little tense.",
        "catphrase.call.unit1": "meow",
        "catphrase.call.unit2": "meow-ya",
        "catphrase.call.unit3": "mii",
        "catphrase.call.explanation": "This one has a clearer rhythm, like gently calling your cat over for food, coming home, or looking your way.",
        "catphrase.praise.unit1": "mi-ya",
        "catphrase.praise.unit2": "meow-woo",
        "catphrase.praise.unit3": "mm-meow",
        "catphrase.praise.explanation": "This one is rounder in rise and fall, like praising your cat for being sweet or doing great.",
        "catphrase.play.unit1": "meow-ow",
        "catphrase.play.unit2": "chu-mii",
        "catphrase.play.unit3": "meow",
        "catphrase.play.explanation": "This one feels more lively, great for teasing with a wand toy, chasing games, or warming the mood up.",
        "catphrase.plan.explanation": "%@ I’ve already linked it to the real cat sample \"%@\", and playback will prioritize that sample.",
        "audio.recorded.label": "Just-recorded clip",
        "audio.imported.label": "Imported audio",
        "error.recorder.permission_denied": "Microphone permission needs to be turned on before I can help you hear what your cat is saying.",
        "error.recorder.start_failed": "Recording couldn’t start smoothly — you can try again in a moment.",
        "error.recorder.no_active_recording": "There isn’t an active recording right now.",
        "error.transcriber.not_supported": "Speech-to-text isn’t supported on this device right now.",
        "error.transcriber.temporarily_unavailable": "Speech recognition isn’t available right now — try again later.",
        "error.transcriber.speech_permission_denied": "Speech recognition permission needs to be turned on before I can write your words into text.",
        "error.transcriber.microphone_permission_denied": "Microphone permission needs to be turned on before I can hear what you just said.",
        "error.sample.resource_missing": "The built-in sample %@ wasn’t found. Check whether the resource is included in the app target.",
        "error.sample.playback_failed": "This cat sound couldn’t play smoothly — try another sample."
    ]

    private static let simplifiedChinese: [String: String] = [
        "app.mode.cat_to_human.title": "猫语转人话",
        "app.mode.human_to_cat.title": "人话转猫语",
        "language.selector.title": "语言",
        "language.selector.subtitle": "选一个你更顺手的应用语言",
        "language.selector.follow_system": "跟随系统",
        "app.mode.cat_to_human.subtitle": "录下来，看看它现在更像是在撒娇、求助，还是想互动。",
        "app.mode.human_to_cat.subtitle": "把你的话变成更贴近猫咪节奏的喵语，温柔一点地回应它。",
        "tone.soothe.title": "安抚",
        "tone.call.title": "召唤",
        "tone.praise.title": "夸奖",
        "tone.play.title": "陪玩",
        "tone.soothe.subtitle": "轻一点，软一点",
        "tone.call.subtitle": "更明确地叫它",
        "tone.praise.subtitle": "像在夸它好乖",
        "tone.play.subtitle": "更活泼地邀请互动",
        "share.interpretation.matched_sample": " 最接近的真实样本是“%@”，相似度约%d%%。",
        "share.interpretation.full": "说猫语帮我听到：%@｜%@。%@%@ 建议：%@",
        "share.phrase.full": "我把“%@”翻成了猫语：%@。这次匹配的是“%@”猫叫样本，语气：%@。",
        "banner.error.title": "这次没有顺利完成",
        "banner.status.title": "当前状态",
        "privacy.banner.title": "隐私设置",
        "privacy.options.button": "隐私选项",
        "privacy.options.error": "隐私选项页这次没能顺利打开，你可以过一会儿再试。",
        "privacy.consent.error": "这次没能顺利准备隐私同意提示；如果当前设备不要求重新征求同意，广告会继续沿用上一次状态。",
        "launch.overlay.title": "说猫语正在准备中",
        "launch.overlay.subtitle": "先替你留一个温柔的等待页，开屏广告准备好就会自然出现。",
        "hero.title": "说猫语",
        "hero.subtitle": "让听不懂和不会说，都变成温柔、轻松、可爱的日常互动。",
        "hero.pill.record": "录音识别",
        "hero.pill.generate": "猫语生成",
        "hero.pill.care": "陪伴建议",
        "mode_selector.cat_to_human.caption": "听懂它的情绪和需求",
        "mode_selector.human_to_cat.caption": "把你的话变成喵语节奏",
        "panel.cat_to_human.title": "猫语转人话",
        "panel.cat_to_human.subtitle.empty": "录下来或导入音频，我会先给你一个温柔、可执行的判断。",
        "panel.cat_to_human.subtitle.result": "操作和结果放在一起，听完后能直接看到这次更像在表达什么。",
        "record.button.stop": "结束倾听",
        "record.button.start": "开始录音",
        "record.helper.recording": "继续说吧，我正在听这段情绪和节奏。",
        "record.helper.idle": "支持直接录一段猫叫，也支持导入已有音频。",
        "action.analyzing": "分析中",
        "action.import_audio": "导入音频",
        "action.import_audio.subtitle": "本地音频也可以",
        "action.finish_recording": "完成这次录音",
        "action.finish_recording.subtitle": "马上给你结果",
        "action.analyze_builtin_sample": "分析内置样本",
        "action.analyze_builtin_sample.subtitle": "直接看看真实样本判断",
        "analysis.in_place.title": "正在替你听懂这段猫语",
        "analysis.in_place.subtitle": "我在先和本地真实样本做对比，再结合时长、响度和节奏，把它整理成更好理解的话。",
        "analysis.in_place.footer": "分析完成后会直接在这里展开结果",
        "panel.human_to_cat.title": "人话转猫语",
        "panel.human_to_cat.subtitle": "输入一句你想说的话，再挑一个语气，我来把它变成更像喵语的节奏。",
        "input.title": "你想对它说什么",
        "input.placeholder": "比如：来吃饭啦，不要怕，我在这儿",
        "speech.button.stop": "结束说话并写进输入框",
        "speech.button.start": "语音转文字",
        "speech.button.stop.subtitle": "我在边听边写，你说完再点一次",
        "speech.button.start.subtitle": "不想打字时，直接说一句就好",
        "tone.section.title": "语气模板",
        "generate.button.title": "生成猫语",
        "generate.button.subtitle": "保留原意，换成更像猫咪的节奏",
        "result.title": "这次更像是在说",
        "result.need.title": "主要需求",
        "result.analysis.title": "这次怎么判断的",
        "result.sample_match.title": "最接近的真实样本",
        "result.sample_match.text": "%@ · %@。当前相似度约%d%%。%@",
        "share.result.button": "分享结果",
        "retry.button": "再试一次",
        "generated.section.title": "你的猫语版本",
        "generated.section.subtitle": "原话：%@",
        "generated.tone_explanation.title": "语气说明",
        "generated.sample.title": "将播放的猫叫样本",
        "generated.sample.text": "%@ · %@。现在默认直接播放这段真实猫叫，不再用生硬的 AI 朗读代替。",
        "generated.playing.button": "猫叫播放中",
        "generated.play.button": "播放对应猫叫",
        "generated.play.button.subtitle": "直接播放匹配到的真实猫咪音频",
        "favorite.button.saved": "已收藏",
        "favorite.button.save": "收藏短语",
        "favorite.button.subtitle": "常用句子以后更快找到",
        "share.phrase.button": "分享这句猫语",
        "sample_library.title": "内置猫叫样本",
        "sample_library.subtitle": "这些真实样本现在既能直接试听，也会作为本地语义对比库，帮助判断录音更像在表达什么。",
        "sample_library.stop": "停止",
        "sample_library.preview": "试听",
        "sample_library.analyze": "分析",
        "sample_library.footer": "当前应用内优先接入 mp3 和 wav 样本做试听与识别；其余 ogg 资源先保留在仓库里，后续统一转码后再开放。",
        "recent.title": "最近互动",
        "recent.subtitle.empty": "还没有记录，做完一次识别或生成就会出现在这里。",
        "recent.subtitle.filled": "帮你把最近几次沟通收在一起，回看会更方便。",
        "recent.empty.title": "现在还是空空的",
        "recent.empty.text": "你可以先试一次录音识别，或者把一句常说的话翻成猫语，这里就会开始有记忆了。",
        "favorites.title": "收藏短语",
        "favorites.subtitle": "高频常用句先放在这里，下次不用重新输入。",
        "tips.title": "互动小贴士",
        "tips.subtitle": "结果只是帮助你更快理解它，不替代你对猫咪状态的持续观察。",
        "tips.item1": "如果它连续高频、急促地叫，先排查食物、水、猫砂盆和门窗。",
        "tips.item2": "如果叫声拉长又比较轻，多半更适合温柔回应，而不是马上逗它。",
        "tips.item3": "人话转猫语更适合做陪伴互动，不建议长时间连续播放。",
        "status.idle": "先选一个方向吧，我会把核心操作放在你手边。",
        "status.recording.listening": "我在认真听它说话。",
        "status.recording.start_failed": "这次没能开始录音。",
        "status.recording.stop_failed": "录音结束时出了点小问题。",
        "error.import.analysis_failed": "这段音频暂时没能顺利分析，你可以换一段更清晰的猫叫试试。",
        "status.import.failed": "导入音频时遇到了一点问题。",
        "error.import.no_file_selected": "没有选中音频文件，这次就先不分析啦。",
        "status.analysis.running": "我在整理它这次更像是在表达什么。",
        "error.sample.missing_in_bundle": "没有找到这段内置样本，先检查它是不是已经打进 App 资源里了。",
        "status.sample.unavailable": "内置样本暂时不可用。",
        "error.sample.analysis_failed": "这段内置样本暂时没能顺利分析，你可以先换一段试听。",
        "status.sample.analysis_failed": "样本分析失败。",
        "status.sample.stopped": "已经停下这段猫叫啦。",
        "status.sample.previewing": "正在试听“%@”样本。",
        "status.sample.playback_failed": "真实猫叫没能顺利播放。",
        "status.transcription.empty": "这次还没有听到清晰的人话。",
        "status.transcription.completed": "已经帮你写进输入框，可以直接生成猫语了。",
        "status.transcription.listening": "开始听你说话了，我会直接写进输入框。",
        "status.transcription.start_failed": "语音转文字这次没能顺利开始。",
        "error.phrase.empty_input": "先输入一句你想对它说的话，我才能帮你翻成猫语。",
        "status.phrase.missing_input": "还缺一句原话。",
        "status.phrase.generated": "已经替你匹配好对应的真实猫叫，现在直接播放。",
        "error.phrase.sample_missing": "这句猫语还没找到可播放的真实样本。",
        "status.phrase.sample_unavailable": "对应样本暂时不可用。",
        "status.phrase.playing_sample": "正在播放“%@”这段真实猫叫。",
        "record.interpretation.detail": "%@ 建议：%@",
        "record.phrase.summary": "语气：%@",
        "status.favorite.removed": "已经帮你从收藏里拿出来了。",
        "status.favorite.added": "这句已经收进常用短语了。",
        "analysis.match.explanation": "这段录音和内置真实样本“%@”最接近，相似度约%d%%。%@ %@",
        "analysis.match.summary": "这次先把录音和本地真实猫叫样本逐个做了比对，再结合时长、响度、停顿和节奏变化整理成语义解释。",
        "analysis.heuristic.partial_match.summary": "这段录音和“%@”有一定相似度，但还不够高，所以这次主要按录音本身的时长、响度和节奏做推断。",
        "analysis.heuristic.no_match.summary": "这次没有找到足够接近的本地样本，结果主要来自录音本身的时长、响度和节奏变化。",
        "heuristic.urgent.emotion": "有点急切",
        "heuristic.urgent.need": "想马上得到回应",
        "heuristic.urgent.explanation": "这段叫声偏短，但峰值比较高，像是在快速提醒你留意它，通常会出现在等吃饭、被门挡住，或想立刻获得关注的时候。",
        "heuristic.urgent.suggestion": "先看看它是不是在饭盆、门口或你常放玩具的位置附近，再用轻声回应它。",
        "heuristic.urgent.confidence": "本地样本相似度一般，这次更像提醒型叫声",
        "heuristic.affectionate.emotion": "想撒娇",
        "heuristic.affectionate.need": "想靠近你或要一点陪伴",
        "heuristic.affectionate.explanation": "这段声音拖得更长、整体力度也比较轻，比较像放松状态下的黏人表达，不太像紧张或抗拒。",
        "heuristic.affectionate.suggestion": "可以蹲下来跟它说话，或者轻轻摸摸下巴，看看它会不会继续靠近。",
        "heuristic.affectionate.confidence": "本地样本相似度一般，这次更像亲近型叫声",
        "heuristic.uneasy.emotion": "有点不安",
        "heuristic.uneasy.need": "想确认环境是不是安全",
        "heuristic.uneasy.explanation": "声音变化比较快，起伏也明显，说明它当下对周围环境更敏感，可能是在确认声音来源、陌生人，或者新出现的气味。",
        "heuristic.uneasy.suggestion": "先帮它把环境安静下来，再观察耳朵和尾巴姿态，避免一下子离它太近。",
        "heuristic.uneasy.confidence": "本地样本相似度一般，这次更像环境刺激触发",
        "heuristic.inviting.emotion": "想互动",
        "heuristic.inviting.need": "希望你看看它或陪它玩一会儿",
        "heuristic.inviting.explanation": "这段叫声时长和响度都比较均衡，像是在稳定地向你发起互动，不像单纯抱怨，也不像特别紧张。",
        "heuristic.inviting.suggestion": "可以先看它是不是把你往玩具、窗边或者常待的位置带，再顺着它的节奏回应。",
        "heuristic.inviting.confidence": "本地样本相似度一般，这次更像邀请型叫声",
        "heuristic.gentle.emotion": "在轻声试探",
        "heuristic.gentle.need": "想确认你有没有在听它",
        "heuristic.gentle.explanation": "整体音量不高，节奏也不算急，通常更像一段日常的小提醒，可能只是想让你看它一眼，或者确认你会不会回应。",
        "heuristic.gentle.suggestion": "先叫叫它的名字，慢一点回应它，再看它会不会继续靠近或带你去某个位置。",
        "heuristic.gentle.confidence": "本地样本相似度一般，这次更像日常沟通型叫声",
        "analysis.dimension.duration": "时长",
        "analysis.dimension.average_intensity": "平均响度",
        "analysis.dimension.peak_intensity": "峰值强度",
        "analysis.dimension.rhythm": "节奏起伏",
        "analysis.dimension.texture": "高频摩擦感",
        "analysis.dimension.pause_ratio": "停顿比例",
        "analysis.dimension.separator": "、",
        "analysis.comparison.summary": "在%@上都更接近“%@”这段样本。",
        "analysis.confidence.high": "和本地真实样本非常接近",
        "analysis.confidence.medium": "和本地真实样本比较接近",
        "analysis.confidence.low": "和本地真实样本有一定相似度",
        "error.audio.too_short": "音频内容太短了，这次还不够分析。",
        "error.audio.conversion_failed": "这段音频暂时没能顺利转成可分析的数据。",
        "catphrase.soothe.unit1": "咪呜",
        "catphrase.soothe.unit2": "呼噜",
        "catphrase.soothe.unit3": "喵呜",
        "catphrase.soothe.explanation": "这句会更偏绵软、收尾更轻，适合在安抚、陪睡或它有点紧张的时候播放。",
        "catphrase.call.unit1": "喵",
        "catphrase.call.unit2": "喵呀",
        "catphrase.call.unit3": "咪",
        "catphrase.call.explanation": "这句节奏会更清楚，像在温柔地叫它过来，适合吃饭、回家或提醒它看向你。",
        "catphrase.praise.unit1": "咪呀",
        "catphrase.praise.unit2": "喵呜",
        "catphrase.praise.unit3": "嗯喵",
        "catphrase.praise.explanation": "这句起伏更圆润，像在夸它好乖、好棒，适合奖励和贴贴时使用。",
        "catphrase.play.unit1": "喵嗷",
        "catphrase.play.unit2": "啾咪",
        "catphrase.play.unit3": "喵",
        "catphrase.play.explanation": "这句会更灵动一点，适合逗猫棒、追逐游戏或想把气氛带热的时候使用。",
        "catphrase.plan.explanation": "%@ 我已经把它对应到“%@”这段真实猫叫，播放时会优先用这段样本。",
        "audio.recorded.label": "刚才这段录音",
        "audio.imported.label": "导入音频",
        "error.recorder.permission_denied": "需要先打开麦克风权限，才能帮你听懂它现在在说什么。",
        "error.recorder.start_failed": "录音没能顺利开始，你可以稍后再试一次。",
        "error.recorder.no_active_recording": "现在还没有正在进行的录音。",
        "error.transcriber.not_supported": "这台设备暂时不支持语音转文字。",
        "error.transcriber.temporarily_unavailable": "语音识别现在不可用，你可以稍后再试。",
        "error.transcriber.speech_permission_denied": "需要先打开语音识别权限，我才能帮你把人话写成文字。",
        "error.transcriber.microphone_permission_denied": "需要先打开麦克风权限，我才能听清你刚才说的话。",
        "error.sample.resource_missing": "没有找到内置样本 %@，可以检查资源是不是已经加入应用目标。",
        "error.sample.playback_failed": "这段猫叫没能顺利播放，你可以换一个样本再试。"
    ]

    private static let spanish = english
    private static let hindi = english
    private static let arabic = english
    private static let portugueseBrazil = english
    private static let russian = english
    private static let japanese = english
    private static let french = english
    private static let german = english

    nonisolated static func value(for key: String, language: AppLanguage) -> String {
        let localizedTable: [String: String]

        switch language {
        case .english:
            localizedTable = english
        case .simplifiedChinese:
            localizedTable = simplifiedChinese
        case .spanish:
            localizedTable = spanish
        case .hindi:
            localizedTable = hindi
        case .arabic:
            localizedTable = arabic
        case .portugueseBrazil:
            localizedTable = portugueseBrazil
        case .russian:
            localizedTable = russian
        case .japanese:
            localizedTable = japanese
        case .french:
            localizedTable = french
        case .german:
            localizedTable = german
        }

        return localizedTable[key] ?? english[key] ?? key
    }
}
