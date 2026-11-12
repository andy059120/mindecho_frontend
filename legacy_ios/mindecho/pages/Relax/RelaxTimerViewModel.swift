//
//  RelaxTimerViewModel.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI
import Combine

class RelaxTimerViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case breath = "呼吸放鬆"
        case mindfulness = "正念呼吸"
        case progressive = "漸進式"
        case meditation = "冥想"
        
        var id: String { rawValue }
    }
    
    @Published var selectedMode: Mode = .breath
    
    struct VideoItem: Identifiable {
        let id = UUID()
        let title: String
        let duration: String
        let topic: String
        let url: URL
    }
    
    struct VideoSection: Identifiable {
        let id = UUID()
        let title: String
        let items: [VideoItem]
    }
    
    private let sections: [VideoSection] = [
        VideoSection(
            title: "呼吸放鬆",
            items: [
                VideoItem(
                    title: "呼吸放鬆法 1",
                    duration: "15 分鐘",
                    topic: "穩定自律神經 幫助睡眠",
                    url: URL(string: "https://www.youtube.com/watch?v=olOYzwaiMcY")!
                ),
                VideoItem(
                    title: "呼吸放鬆法 2",
                    duration: "10 分鐘",
                    topic: "幫助調息",
                    url: URL(string: "https://www.youtube.com/watch?v=yz2NjOUMBIE&list=PLgzxdlIcydXAz-XT2GLihQlH9q_nEQKTk")!
                ),
                VideoItem(
                    title: "呼吸放鬆法 3",
                    duration: "5 分鐘",
                    topic: "吸4-停7-吐8",
                    url: URL(string: "https://www.youtube.com/watch?v=sYDwONgry2A")!
                ),
                VideoItem(
                    title: "呼吸放鬆法 4",
                    duration: "10 分鐘",
                    topic: "深呼吸放鬆練習引導",
                    url: URL(string: "https://www.youtube.com/watch?v=UrMa3uOq67g")!
                )
            ]
        ),
        VideoSection(
            title: "正念呼吸",
            items: [
                VideoItem(
                    title: "正念呼吸 1",
                    duration: "10 分鐘",
                    topic: "穩定注意力",
                    url: URL(string: "https://www.youtube.com/watch?v=9XzRNDLlSSQ&list=PL5nF87IeD9iodsrCfyUlcpuv2kzqkvm3K&index=2")!
                ),
                VideoItem(
                    title: "正念呼吸 2",
                    duration: "12 分鐘",
                    topic: "緩解焦慮",
                    url: URL(string: "https://www.youtube.com/watch?v=XvUJl71hHhM&list=PL69Lw5aOg_-_5b4JigAKPJZI1nQafkZhv&index=3")!
                ),
                VideoItem(
                    title: "正念呼吸 3",
                    duration: "30 分鐘",
                    topic: "回到呼吸",
                    url: URL(string: "https://www.youtube.com/watch?v=y0oJoGT1o6U&list=PLqC8PGr0r_opMB9UhOgCsJn8gkaIeXXKY")!
                )
            ]
        ),
        VideoSection(
            title: "漸進式",
            items: [
                VideoItem(
                    title: "漸進式放鬆法 1",
                    duration: "12 分鐘",
                    topic: "釋放緊繃",
                    url: URL(string: "https://www.youtube.com/watch?v=TEok1rznak4")!
                ),
                VideoItem(
                    title: "漸進式放鬆法 2",
                    duration: "10 分鐘",
                    topic: "舒緩身體",
                    url: URL(string: "https://www.youtube.com/watch?v=al9vb6myEdw")!
                )
            ]
        ),
        VideoSection(
            title: "冥想",
            items: [
                VideoItem(
                    title: "冥想 1",
                    duration: "15 分鐘",
                    topic: "放鬆與覺察",
                    url: URL(string: "https://www.youtube.com/watch?v=LrxvPgGXLvg")!
                ),
                VideoItem(
                    title: "韓瑞克森肌肉放鬆訓練",
                    duration: "20 分鐘",
                    topic: "深層放鬆",
                    url: URL(string: "https://www.youtube.com/watch?v=Y77208p_zo4")!
                ),
                VideoItem(
                    title: "冥想 2",
                    duration: "10 分鐘",
                    topic: "放鬆入睡",
                    url: URL(string: "https://www.youtube.com/watch?v=tFSpuL4nfgM")!
                )
            ]
        ),
        
    ]
    
    func sections(for mode: Mode) -> [VideoSection] {
        let filtered = sections.filter { $0.title == mode.rawValue }
        if filtered.isEmpty {
            return sections
        }
        return filtered
    }
}

struct RelaxTimerPreviewWrapper: View {
    @StateObject private var viewModel = RelaxTimerViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("預覽模式：\(viewModel.selectedMode.rawValue)")
                .font(.headline)
            ForEach(viewModel.sections(for: viewModel.selectedMode)) { section in
                Text(section.title)
                    .font(.subheadline.bold())
                ForEach(section.items) { item in
                    Text(item.title)
                        .font(.subheadline)
                }
            }
        }
        .padding(16)
        .previewLayout(.sizeThatFits)
    }
}

#Preview {
    RelaxTimerPreviewWrapper()
}
