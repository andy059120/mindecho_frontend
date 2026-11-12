import Foundation

// MARK: - 首頁相關常數
struct HomeConstants {
    
    // MARK: - 每日檢測
    struct DailyCheckIn {
        static let questions = [
            DailyCheckInQuestion(
                title: "身體感覺有活力嗎？",
                subtitle: "評估你的身體活力狀態",
                category: .physical
            ),
            DailyCheckInQuestion(
                title: "今天心情如何？",
                subtitle: "評估你的情緒狀態",
                category: .mental
            ),
            DailyCheckInQuestion(
                title: "腦筋覺得靈活好使嗎？",
                subtitle: "評估你的思緒清晰度",
                category: .emotional
            ),
            DailyCheckInQuestion(
                title: "這一夜的睡眠品質如何？",
                subtitle: "評估你的睡眠品質",
                category: .sleep
            ),
            DailyCheckInQuestion(
                title: "今天的食慾如何？",
                subtitle: "評估你的飲食狀態",
                category: .appetite
            )
        ]
        
        static let moodOptions = MoodCatalog.all.map {
            MoodOption(emoji: $0.emoji, label: $0.label, value: $0.value)
        }
    }
    
    // MARK: - 生理節律
    struct Biorhythm {
        static let physicalCycle = 23    // 體力週期
        static let emotionalCycle = 28   // 情緒週期
        static let intellectualCycle = 33 // 智力週期
        
        // 個人模式最少需要的數據天數
        static let minimumDataDays = 14
        
        // 月份標籤
        static let monthLabels = ["1月", "2月", "3月", "4月", "5月", "6月",
                                 "7月", "8月", "9月", "10月", "11月", "12月"]
    }
    
    // MARK: - 心理健康資源
    struct Resources {
        static let mentalHealthResources = [
            MentalHealthResource(
                title: "24 小時求助資源",
                subtitle: "查看心理諮詢熱線、免費協談專線與其他求助管道",
                icon: "phone.connection.fill",
                buttonText: "查看資源",
                action: .hotline
            ),
            MentalHealthResource(
                title: "情緒管理小技巧",
                subtitle: "如果感到難受或焦慮，你可以試著這樣做......",
                icon: "heart.circle.fill",
                buttonText: "查看更多",
                action: .techniques
            ),
            MentalHealthResource(
                title: "放鬆訓練",
                subtitle: "透過呼吸與冥想，幫助自己慢慢穩定下來",
                icon: "leaf.fill",
                buttonText: "開始練習",
                action: .relax
            )
        ]
    }
    
    // MARK: - 心理測驗
    struct Tests {
        static let sharedOverviewText = """
        在接下來的測驗中，我們會使用幾份常見的心理量表。這些量表不是考試，也不是診斷工具，沒有對錯、沒有好壞之分。

        它們的目的，是幫助我們更了解你最近一段時間的心理狀態、感受與因應方式，也讓你有一個機會，靜下來覺察自己的內在經驗。

        請依照你最真實的感受作答，不需要迎合期待，也不需要擔心結果會被貼標籤。所有回答都只代表當下的狀態，而非你這個人本身。
        """

        static let sharedClosingText = """
        最後想提醒你：這些測驗的目的不是貼標籤，而是理解與關懷。

        如果你在填寫時發現自己有一些困難的感受，那並不代表你脆弱，而是代表你正在覺察自己。你不需要獨自承擔這些感受，請尋求專業人員的協助。
        """

        static let psychologicalTests = [
            makeTest(action: .cesd, title: "CES-D 憂鬱量表", subtitle: "CES-D Depression Scale", icon: "heart.circle.fill"),
            makeTest(action: .bsrs5, title: "BSRS-5 簡式健康量表", subtitle: "Brief Symptom Rating Scale-5", icon: "list.clipboard.fill"),
            makeTest(action: .sats, title: "SATS 消沉傾向量表", subtitle: "SATS Scale", icon: "cloud.rain.fill"),
            makeTest(action: .psycap, title: "PCS 心理資本量表", subtitle: "Psychological Capital Scale", icon: "sparkles"),
            makeTest(action: .cdrisc, title: "CD-RISC 復原力量表", subtitle: "Connor-Davidson Resilience Scale", icon: "shield.lefthalf.fill"),
            makeTest(action: .pansi, title: "PANSI 正負向自殺意念量表", subtitle: "Positive and Negative Suicide Ideation", icon: "exclamationmark.triangle.fill"),
            makeTest(action: .bss, title: "BSS 自殺意念評估", subtitle: "Beck Scale for Suicide Ideation", icon: "waveform.path.ecg"),
            makeTest(action: .rfq8, title: "RFQ-8 心智化量表", subtitle: "Reflective Functioning Questionnaire-8", icon: "brain.head.profile"),
            makeTest(action: .aq10, title: "AQ-10 自閉光譜量表", subtitle: "Autism Spectrum Quotient-10", icon: "person.2.fill")
        ]
        
        private static func makeTest(action: TestAction, title: String, subtitle: String, icon: String) -> PsychologicalTest {
            let count = action == .rfq8 ? 8 : (scaleMetaByAction[action]?.questionCount ?? 0)
            let minutes = max(1, Int(ceil(Double(count) / 2.0)))
            return PsychologicalTest(
                title: title,
                subtitle: subtitle,
                icon: icon,
                duration: "\(minutes)分鐘",
                questions: "\(count)題",
                action: action
            )
        }

        static let scaleMetas: [ScaleMeta] = [
            ScaleMeta(
                action: .cesd,
                code: "CESD20",
                title: "CES-D 憂鬱量表",
                questionCount: 20,
                instructions: "請依「過去一週內」的情形作答（4、8、12、16為反向題）",
                reverseIndices: Set([4, 8, 12, 16])
            ),
            ScaleMeta(
                action: .bsrs5,
                code: "BSRS5",
                title: "BSRS-5 簡式健康量表",
                questionCount: 5,
                instructions: "最近一週內的感受",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .sats,
                code: "SATS8",
                title: "SATS 消沉傾向量表",
                questionCount: 8,
                instructions: "請依近期感受作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .aq10,
                code: "AQ10",
                title: "AQ-10 自閉光譜量表",
                questionCount: 10,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .psycap,
                code: "PCS12",
                title: "PCS 心理資本量表",
                questionCount: 12,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .cdrisc,
                code: "CDRISC25",
                title: "CD-RISC 復原力量表",
                questionCount: 25,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .pansi,
                code: "PANSI14",
                title: "PANSI 正負向自殺意念量表",
                questionCount: 14,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            ),
            ScaleMeta(
                action: .bss,
                code: "BSS21",
                title: "BSS 自殺意念評估",
                questionCount: 21,
                instructions: "請依實際狀況作答",
                reverseIndices: Set<Int>()
            )
        ]

        static let scaleMetaByAction: [TestAction: ScaleMeta] = {
            var map: [TestAction: ScaleMeta] = [:]
            for meta in scaleMetas {
                map[meta.action] = meta
            }
            return map
        }()
    }
    
    // MARK: - 圖表設定
    struct Charts {
        static let defaultAnimationDuration: Double = 1.0
        static let chartHeight: CGFloat = 200
        static let cardCornerRadius: CGFloat = 12
        static let cardShadowRadius: CGFloat = 2
        
        // 時間週期選項
        static let timePeriodOptions = ["本週", "最近七週", "最近七月", "最近三年半"]
    }
    
    // MARK: - UserDefaults 鍵值
    struct UserDefaultsKeys {
        static let todayScores = "home_today_scores"
        static let weeklyScores = "home_weekly_scores"
        static let birthDate = "home_birth_date"
        static let biorhythmMode = "home_biorhythm_mode"
    }
    
    // MARK: - 動畫設定
    struct Animation {
        static let cardAppearDuration: Double = 0.3
        static let biorhythmAnimationDuration: Double = 2.0
        static let moodSelectionDuration: Double = 0.2
    }
}
