//
//  ContentView.swift
//  mindecho
//
//  Created by 鄧巧婕 on 2025/7/20.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var tabTourState = TabTourState.shared
    @StateObject private var mainTabState = MainTabState.shared
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // 已登入
                mainTabView
            } else {
                // 未登入 
                WelcomePage()
            }
        }
        .environmentObject(tabTourState)
        .environmentObject(mainTabState)
        .task {
            authViewModel.attemptAutoLoginOnLaunch()
        }
        .fullScreenCover(isPresented: $authViewModel.shouldShowDailyCheckIn) {
            DailyCheckInView(isPresented: $authViewModel.shouldShowDailyCheckIn)
        }
    }
    
    // MARK: - TabView
    private var mainTabView: some View {
        MainTabView()
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var mainTabState: MainTabState
    @EnvironmentObject private var tabTourState: TabTourState
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $mainTabState.selectedTab) {
                ForEach(MainTab.allCases) { tab in
                    NavigationView {
                        tab.view
                    }
                    .tag(tab)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            if !(mainTabState.selectedTab == .chat && keyboardObserver.isVisible) {
                CustomTabBar(selectedTab: $mainTabState.selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlayPreferenceValue(TabTourAnchorKey.self) { anchors in
            if tabTourState.isActive, let anchor = anchors[tabTourState.step] {
                TabTourOverlay(
                    anchor: anchor,
                    step: tabTourState.step,
                    onNext: advanceTour,
                    onClose: endTour
                )
            }
        }
        .accentColor(.orange)
        .animation(.easeOut(duration: 0.2), value: keyboardObserver.isVisible)
    }

    private func advanceTour() {
        if let next = tabTourState.step.next {
            tabTourState.step = next
        } else {
            endTour()
        }
    }

    private func endTour() {
        tabTourState.isActive = false
    }
}

private final class KeyboardObserver: ObservableObject {
    @Published var isVisible = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in false }

        Publishers.Merge(willShow, willHide)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: &$isVisible)
    }
}

// MARK: - Tabs
enum MainTab: String, CaseIterable, Identifiable {
    case home, chat, diary, profile
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .home: return "首頁"
        case .chat: return "聊天"
        case .diary: return "追蹤"
        case .profile: return "個人檔案"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .chat: return "bubble.left"
        case .diary: return "chart.bar"
        case .profile: return "person"
        }
    }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .home: HomeView()
        case .chat: ChatListPage()
        case .diary: DiaryMainView()
        case .profile: ProfileView()
        }
    }
}

final class MainTabState: ObservableObject {
    static let shared = MainTabState()
    @Published var selectedTab: MainTab = .home
}

enum TabTourStep: String, CaseIterable, Identifiable {
    case home, chat, diary, profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "首頁"
        case .chat: return "聊天"
        case .diary: return "追蹤"
        case .profile: return "個人檔案"
        }
    }

    var message: String {
        switch self {
        case .home: return "總覽你的狀態與每日提醒。"
        case .chat: return "和 AI 進行對話、整理感受。"
        case .diary: return "記錄情緒與日記、追蹤變化。"
        case .profile: return "管理個人資料與重要聯絡資訊。"
        }
    }

    var next: TabTourStep? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self),
              index + 1 < all.count else { return nil }
        return all[index + 1]
    }
}

final class TabTourState: ObservableObject {
    static let shared = TabTourState()
    @Published var isActive = false
    @Published var step: TabTourStep = .home
}

private extension MainTab {
    var tourStep: TabTourStep {
        switch self {
        case .home: return .home
        case .chat: return .chat
        case .diary: return .diary
        case .profile: return .profile
        }
    }
}

// MARK: - Custom Tab Bar
private struct CustomTabBar: View {
    @Binding var selectedTab: MainTab
    
    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 12
            let padding: CGFloat = 12
            let count = CGFloat(MainTab.allCases.count)
            let totalSpacing = spacing * (count - 1)
            let itemWidth = (geo.size.width - totalSpacing - padding * 2) / count
            
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: spacing) {
                    ForEach(MainTab.allCases) { tab in
                        TabButton(
                            tab: tab,
                            isSelected: tab == selectedTab,
                            fixedWidth: itemWidth
                        ) {
                            selectedTab = tab
                        }
                        .anchorPreference(
                            key: TabTourAnchorKey.self,
                            value: .bounds
                        ) { [tab.tourStep: $0] }
                    }
                }
                .padding(.horizontal, padding)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(.ultraThinMaterial)
        }
        .frame(height: 70)
    }
}

private struct TabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let fixedWidth: CGFloat?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                Text(tab.title)
                    .font(.footnote)
            }
            .frame(width: fixedWidth ?? 60)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TabTourAnchorKey: PreferenceKey {
    static var defaultValue: [TabTourStep: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TabTourStep: Anchor<CGRect>], nextValue: () -> [TabTourStep: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct TabTourOverlay: View {
    let anchor: Anchor<CGRect>
    let step: TabTourStep
    let onNext: () -> Void
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let rect = proxy[anchor].insetBy(dx: -6, dy: -6).offsetBy(dx: 0, dy: 48)
            let bubbleWidth = min(260, proxy.size.width - 32)
            let bubbleX = min(proxy.size.width - bubbleWidth / 2 - 8, max(bubbleWidth / 2 + 8, rect.midX))
            let bubbleY = max(60, rect.minY - 110)

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.6)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                                    .blendMode(.destinationOut)
                            )
                    )
                    .compositingGroup()
                    .ignoresSafeArea()
                    .onTapGesture { onNext() }

                VStack(alignment: .leading, spacing: 8) {
                    Text(step.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(step.message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    HStack {
                        Button("略過") { onClose() }
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Button(step.next == nil ? "完成" : "下一步") { onNext() }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                }
                .padding(12)
                .background(Color.black.opacity(0.75))
                .cornerRadius(12)
                .frame(width: bubbleWidth, alignment: .leading)
                .position(x: bubbleX, y: bubbleY)
            }
        }
    }
}

// MARK: - 開發中頁面
struct DevelopingView: View {
    let pageName: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 圖標
            Image(systemName: "hammer.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            // 標題
            Text("\(pageName)功能")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 副標題
            Text("正在開發中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 描述
            VStack(spacing: 8) {
                Text("我們正在努力為您打造更好的體驗")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("敬請期待 🚀")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 底部提示
            VStack(spacing: 4) {
                Text("目前可使用聊天功能")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("請點擊下方「聊天」頁籤")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // 🎯 臨時測試：長按 5 秒直接登出
                Text("長按此處 5 秒可登出")
                    .font(.caption2)
                    .foregroundColor(.red.opacity(0.7))
                    .onLongPressGesture(minimumDuration: 5.0) {
                        AuthService.shared.logout()
                    }
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
}

#Preview("MainTabView") {
    MainTabView()
}

#Preview("開發中頁面") {
    DevelopingView(pageName: "測試")
}
