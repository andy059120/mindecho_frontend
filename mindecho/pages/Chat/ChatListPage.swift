import SwiftUI

struct ChatListPage: View {
    // MARK: - Hook 狀態管理
    @StateObject private var chatHook = ChatHook()
    
    // MARK: - UI 狀態
    @State private var navigateToNewChat = false
    @State private var newChatSession: ChatSession?
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: ChatSession?
    @State private var selectedMode: TherapyMode = .initial
    @State private var showingModeIntro = false
    @State private var introMode: TherapyMode = .initial
    @State private var showingTitlePrompt = false
    @State private var pendingTitle = ""
    
    // MARK: - 計算屬性
    var filteredChats: [ChatSession] {
        chatHook.chatSessions
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 主標題區域
                ChatHeader()
                
                // 聊天室卡片
                VStack(alignment: .leading, spacing: 12) {
                    Text("聊天室")
                        .font(.title3.bold())
                        .foregroundColor(AppColors.titleColor)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(modeCards) { card in
                                TherapyModeResourceCard(card: card) {
                                    startNewChat(for: card.mode)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 8)
                
                // 聊天列表內容
                ChatListContent(
                    filteredChats: filteredChats,
                    isLoading: chatHook.isLoading,
                    onDeleteSession: deleteSession,
                    chatHook: chatHook,
                    onStartChat: startNewChat
                )
                
                Spacer()
            }
            .background(AppColors.lightYellow.ignoresSafeArea())
            .task {
                await chatHook.loadSessions()
            }
            .background(
                // 隱藏的 NavigationLink，用於程式化導航
                NavigationLink(
                    destination: Group {
                        if let session = newChatSession {
                            ChatDetailPage(session: session, chatHook: chatHook)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: $navigateToNewChat
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .alert("確認刪除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {
                    sessionToDelete = nil
                }
                Button("刪除", role: .destructive) {
                    if let session = sessionToDelete {
                        Task {
                            await chatHook.deleteSession(session.id)
                        }
                        sessionToDelete = nil
                    }
                }
            } message: {
                if let session = sessionToDelete {
                    Text("確定要刪除「\(session.title)」對話嗎？此操作無法復原。")
                }
            }
            .alert("錯誤", isPresented: $chatHook.showError) {
                Button("確定", role: .cancel) {
                    chatHook.error = nil
                }
            } message: {
                if let error = chatHook.error {
                    Text(error)
                }
            }
            .alert("聊天室名稱", isPresented: $showingTitlePrompt) {
                TextField("可選填", text: $pendingTitle)
                Button("略過") {
                    Task {
                        if let newSession = await chatHook.createNewSession(mode: selectedMode, title: nil) {
                            newChatSession = newSession
                            navigateToNewChat = true
                        }
                    }
                }
                Button("確定") {
                    Task {
                        let title = pendingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let newSession = await chatHook.createNewSession(
                            mode: selectedMode,
                            title: title.isEmpty ? nil : title
                        ) {
                            newChatSession = newSession
                            navigateToNewChat = true
                        }
                    }
                }
            } message: {
                Text("請輸入聊天室名稱（可留空）")
            }
            .sheet(isPresented: $showingModeIntro) {
                ModeIntroductionSheet(
                    mode: introMode,
                    onCancel: {
                        showingModeIntro = false
                    },
                    onConfirm: {
                        showingModeIntro = false
                        showingTitlePrompt = true
                    }
                )
            }
        }
    }
    
    // MARK: - 刪除功能
    private func deleteSession(_ session: ChatSession) {
        sessionToDelete = session
        showingDeleteAlert = true
    }
    
    private func deleteSessionsAtOffsets(_ offsets: IndexSet) {
        for index in offsets {
            let session = filteredChats[index]
            Task {
                await chatHook.deleteSession(session.id)
            }
        }
    }
    
    private func startNewChat(for mode: TherapyMode) {
        guard !chatHook.isLoading else { return }
        selectedMode = mode
        introMode = mode
        pendingTitle = ""
        showingModeIntro = true
    }
    
    private var modeCards: [TherapyModeCard] {
        [
            TherapyModeCard(
                mode: .initial,
                title: "初談",
                subtitle: "溫暖接住，建立安全感",
                icon: "sparkles"
            ),
            TherapyModeCard(
                mode: .mbtMode,
                title: "MBT",
                subtitle: "理解自己與他人感受，增進關係",
                icon: "person.2.fill"
            ),
            TherapyModeCard(
                mode: .cbtMode,
                title: "CBT",
                subtitle: "探索想法－情緒－行為的連結",
                icon: "brain.head.profile"
            ),
            TherapyModeCard(
                mode: .dbtMode,
                title: "DBT",
                subtitle: "穩定情緒、降低衝動，練習界線與應對",
                icon: "waveform.path.ecg"
            ),
            TherapyModeCard(
                mode: .mbctMode,
                title: "MBCT",
                subtitle: "正念覺察，安定情緒起伏",
                icon: "leaf"
            )
        ]
    }
}

private struct ModeIntroductionSheet: View {
    let mode: TherapyMode
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                ModeIntroductionView(mode: mode)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("取消") {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(AppColors.darkBrown)
                    .cornerRadius(12)
                    
                    Button("確定") {
                        onConfirm()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.darkBrown)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("聊天室介紹")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppColors.lightYellow.ignoresSafeArea())
        }
        .presentationBackground(AppColors.lightYellow)
    }
}

// MARK: - 主標題區域元件
struct ChatHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("聊天室")
                .font(.title2.bold())
                .foregroundColor(AppColors.titleColor)
            Text("選擇一種對話方式，開始今天的陪伴")
                .font(.subheadline)
                .foregroundColor(AppColors.titleColor.opacity(0.7))
        }
        .padding(.top, 16)
    }
}

// MARK: - 聊天列表內容
struct ChatListContent: View {
    let filteredChats: [ChatSession]
    let isLoading: Bool
    let onDeleteSession: (ChatSession) -> Void
    let chatHook: ChatHook
    let onStartChat: (TherapyMode) -> Void
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if filteredChats.isEmpty {
                EmptyChatState(onStartChat: onStartChat)
            } else {
                ChatSessionsSection(
                    sessions: filteredChats.filter { !$0.lastMessage.isEmpty },
                    chatHook: chatHook,
                    onDeleteSession: onDeleteSession
                )
            }
        }
    }
}

// MARK: - 聊天紀錄區塊
private struct ChatSessionsSection: View {
    let sessions: [ChatSession]
    let chatHook: ChatHook
    let onDeleteSession: (ChatSession) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("聊天紀錄")
                .font(.title3.bold())
                .foregroundColor(AppColors.titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            ChatSessionsList(
                sessions: sessions,
                chatHook: chatHook,
                onDeleteSession: onDeleteSession
            )
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - 聊天會話列表
struct ChatSessionsList: View {
    let sessions: [ChatSession]
    let chatHook: ChatHook
    let onDeleteSession: (ChatSession) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sessions) { session in
                    NavigationLink(destination: ChatDetailPage(session: session, chatHook: chatHook)) {
                        ChatListItemView(session: session)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // 刪除按鈕
                        Button(role: .destructive, action: {
                            onDeleteSession(session)
                        }) {
                            Label("刪除", systemImage: "trash")
                        }
                        
                        // 編輯按鈕
                        Button(action: {
                            // TODO: 實現編輯功能
                        }) {
                            Label("編輯", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button(action: {
                            // TODO: 分享功能
                        }) {
                            Label("分享對話", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            // TODO: 標記重要
                        }) {
                            Label("標記重要", systemImage: "star")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            onDeleteSession(session)
                        }) {
                            Label("刪除對話", systemImage: "trash")
                        }
                    }
                    
                    if session.id != sessions.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - 載入視圖
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("載入中...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 聊天列表項目（保持原樣）
struct ChatListItemView: View {
    let session: ChatSession
    
    var body: some View {
        HStack(spacing: 16) {
            // 模式圖標
            ZStack {
                Circle()
                    .fill(session.therapyMode.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(session.therapyMode.shortName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(session.therapyMode.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.titleColor)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatDate(session.lastUpdated))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(session.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !session.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(session.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.chatBackground)
                                .foregroundColor(AppColors.chatModeColor)
                                .cornerRadius(8)
                        }
                        
                        if session.tags.count > 2 {
                            Text("+\(session.tags.count - 2)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "zh_Hant_TW")
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - 空狀態視圖
struct EmptyChatState: View {
    let onStartChat: (TherapyMode) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("聊天紀錄")
                .font(.title3.bold())
                .foregroundColor(AppColors.titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 56))
                    .foregroundColor(AppColors.titleColor.opacity(0.5))
                
                Text("還沒有聊天紀錄")
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))
                
                Text("開始您的第一次心靈對話")
                    .font(.subheadline)
                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                
                Button("開始聊天") {
                    onStartChat(.initial)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(AppColors.orange)
                .cornerRadius(12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}

private struct TherapyModeCard: Identifiable {
    let mode: TherapyMode
    let title: String
    let subtitle: String
    let icon: String
    
    var id: String { mode.rawValue }
}

private struct TherapyModeResourceCard: View {
    let card: TherapyModeCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: card.icon)
                        .font(.title2)
                        .foregroundColor(AppColors.darkBrown)
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.darkBrown)
                    
                    Text(card.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.darkBrown.opacity(0.7))
                        .lineLimit(2)
                    
                    Text("開始對話")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.darkBrown)
                        .cornerRadius(8)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .frame(width: 160, height: 150)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.resourceCardYellow,
                        AppColors.resourceCardOrange,
                        AppColors.orange.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(HomeConstants.Charts.cardCornerRadius)
            .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChatListPage()
}
