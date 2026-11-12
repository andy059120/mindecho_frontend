import SwiftUI

struct ChatDetailPage: View {
    let session: ChatSession
    
    // MARK: - Hook 狀態管理
    @ObservedObject var chatHook: ChatHook
    
    // MARK: - UI 狀態
    @State private var messageText = ""
    @State private var selectedMode: TherapyMode
    @State private var showingModeChangeConfirmation = false
    @State private var targetMode: TherapyMode?
    @State private var showingClearChatAlert = false
    @State private var showingInitialEndedAlert = false
    @State private var nextMode: TherapyMode?
    @State private var handoffSession: ChatSession?
    @State private var navigatingToHandoff = false
    @Environment(\.presentationMode) var presentationMode
    
    init(session: ChatSession, chatHook: ChatHook) {
        self.session = session
        self.chatHook = chatHook
        self._selectedMode = State(initialValue: session.therapyMode)
    }
    
    // MARK: - 計算屬性
    private var messages: [ChatMessage] {
        chatHook.getMessages(for: session.id)
    }

    private var isSendingMessage: Bool {
        chatHook.isSendingMessage(in: session.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題欄
            ChatHeaderView(
                session: session,
                selectedMode: $selectedMode,
                onModeChange: { newMode in
                    if newMode != selectedMode {
                        targetMode = newMode
                        showingModeChangeConfirmation = true
                    }
                },
                onBack: {
                    presentationMode.wrappedValue.dismiss()
                },
                onClearChat: {
                    showingClearChatAlert = true
                }
            )
            
            // 聊天消息列表
            ChatMessagesView(
                messages: messages,
                selectedMode: selectedMode,
                isTyping: chatHook.isTyping(in: session.id),
                onTapMessages: dismissKeyboard
            )
            
            // 輸入框
            ChatInputView(
                messageText: $messageText,
                onSend: sendMessage,
                mode: selectedMode,
                isDisabled: isSendingMessage,
                isSending: isSendingMessage,
                allowsEmptySend: chatHook.initialModeBySession[session.id]?.sessionEnded == true
            )
        }
        .background(AppColors.chatBackground)
        .navigationBarHidden(true)
        .overlay(
            // 模式切換確認對話框
            Group {
                if showingModeChangeConfirmation, let target = targetMode {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingModeChangeConfirmation = false
                                targetMode = nil
                            }
                        
                        ModeChangeConfirmationView(
                            currentMode: selectedMode,
                            targetMode: target,
                            onConfirm: {
                                selectedMode = target
                                Task {
                                    await chatHook.updateSessionMode(session.id, mode: target)
                                }
                                showingModeChangeConfirmation = false
                                targetMode = nil
                            },
                            onCancel: {
                                showingModeChangeConfirmation = false
                                targetMode = nil
                            }
                        )
                        .padding(.horizontal, 32)
                    }
                }
            }
        )
        .alert("清除對話", isPresented: $showingClearChatAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                clearCurrentChat()
            }
        } message: {
            Text("確定要清除當前對話的所有訊息嗎？此操作無法復原。")
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
        .alert("初談已結束", isPresented: $showingInitialEndedAlert) {
            if let nextMode {
                Button("開始\(nextMode.shortName)對話") {
                    createHandoffSession(using: nextMode)
                }
            }
            Button("回到聊天頁面") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(recommendationMessage())
        }
        .task {
            // 頁面載入時載入聊天記錄
            await chatHook.loadChatHistory(for: session.id)
        }
        .onChange(of: chatHook.initialModeBySession[session.id]?.selectedMode) { _, mode in
            if let mode {
                nextMode = mode
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let handoffSession {
                        ChatDetailPage(session: handoffSession, chatHook: chatHook)
                    }
                },
                isActive: $navigatingToHandoff
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    // MARK: - 私有方法
    
    private func clearCurrentChat() {
        Task {
            await chatHook.clearMessages(for: session.id)
        }
    }
    
    private func sendMessage() {
        if chatHook.initialModeBySession[session.id]?.sessionEnded == true {
            let info = chatHook.initialModeBySession[session.id]
            nextMode = info?.selectedMode ?? TherapyMode.fromInitialMode(info?.rawSelectedMode)
            showingInitialEndedAlert = true
            messageText = ""
            return
        }
        let content = messageText
        
        Task {
            if await chatHook.sendMessage(to: session.id, content: content) {
                messageText = ""
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func createHandoffSession(using mode: TherapyMode) {
        showingInitialEndedAlert = false
        Task {
            if let newSession = await chatHook.createHandoffSession(from: session.id, to: mode) {
                handoffSession = newSession
                navigatingToHandoff = true
            }
        }
    }

    private func recommendationMessage() -> String {
        guard let nextMode else {
            return "這段初談已經結束，目前系統還沒有提供明確的下一步模式建議。你可以先回到聊天頁面，自行選擇 CBT、DBT、MBT 或 MBCT 開始新對話；這不代表你很難被幫助，只是這次初談沒有產出明確分類結果。"
        }

        let modeText: String
        switch nextMode {
        case .cbtMode: modeText = "CBT"
        case .dbtMode: modeText = "DBT"
        case .mbtMode: modeText = "MBT"
        case .mbctMode: modeText = "MBCT"
        case .chatMode, .initial:
            modeText = "聊天"
        }
        return "這段初談已經結束。系統建議你接下來使用「\(modeText)」模式進一步對談，請回到聊天頁面開始新的\(modeText)對話。"
    }
}

// MARK: - 聊天訊息視圖
struct ChatMessagesView: View {
    let messages: [ChatMessage]
    let selectedMode: TherapyMode
    let isTyping: Bool
    let onTapMessages: () -> Void
    
    private let bottomAnchorId = "chat-bottom-anchor"
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    // 打字指示器
                    if isTyping {
                        HStack {
                            HStack(alignment: .top, spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selectedMode.color.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Text(selectedMode.shortName)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedMode.color)
                                }
                                
                                TypingIndicatorView()
                                
                                Spacer()
                            }
                            
                            Spacer()
                        }
                        .id("typing")
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorId)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .contentShape(Rectangle())
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                onTapMessages()
            }
            .onAppear {
                scrollToBottom(using: proxy, animated: false)
            }
            .onChange(of: messages.last?.id) { _, _ in
                scrollToBottom(using: proxy, animated: false)
            }
            .onChange(of: isTyping) { _, _ in
                scrollToBottom(using: proxy, animated: false)
            }
        }
    }
    
    private func scrollToBottom(using proxy: ScrollViewProxy, animated: Bool = true) {
        let action = {
            proxy.scrollTo(bottomAnchorId, anchor: .bottom)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if animated {
                withAnimation(.easeOut(duration: 0.3)) {
                    action()
                }
            } else {
                action()
            }
        }
    }
}

// MARK: - 聊天標題欄（保持原樣，但使用 AppColors）
struct ChatHeaderView: View {
    let session: ChatSession
    @Binding var selectedMode: TherapyMode
    let onModeChange: (TherapyMode) -> Void
    let onBack: () -> Void
    let onClearChat: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 頂部導航欄
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("返回")
                            .font(.subheadline)
                    }
                    .foregroundColor(AppColors.chatModeColor)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.titleColor)
                        .lineLimit(1)
                    
                    Text("最後活動: \(formatRelativeTime(session.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 會話選項按鈕
                Menu {
                    Button(action: {
                        // TODO: 分享功能
                    }) {
                        Label("分享對話", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // TODO: 匯出功能
                    }) {
                        Label("匯出對話", systemImage: "doc.text")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        onClearChat()
                    }) {
                        Label("清除對話", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // 模式選擇器
            HStack(spacing: 8) {
                ForEach(TherapyMode.selectableCases, id: \.self) { mode in
                    Button(action: {
                        if selectedMode != mode {
                            onModeChange(mode)
                        }
                    }) {
                        Text(mode.shortName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedMode == mode ? .white : mode.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedMode == mode ? mode.color : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(mode.color, lineWidth: 1)
                                    )
                            )
                    }
                    .scaleEffect(selectedMode == mode ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedMode)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "剛剛"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分鐘前"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)小時前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            formatter.locale = Locale(identifier: "zh_Hant_TW")
            return formatter.string(from: date)
        }
    }
}



#Preview {
    NavigationView {
        ChatDetailPage(session: ChatSession(
            title: "測試對話",
            therapyMode: .chatMode,
            lastMessage: "最後一條消息",
            tags: ["測試"]
        ), chatHook: ChatHook())
    }
}
