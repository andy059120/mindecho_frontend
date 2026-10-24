import SwiftUI

// MARK: - 心理健康資源區塊
struct MentalHealthResourcesSection: View {
    @State private var showingHotlineSheet = false
    @State private var showingGuideSheet = false
    @State private var showingTechniquesSheet = false
    @State private var showingMapSheet = false
    @State private var showingRelaxSheet = false
    
    private let resources = HomeConstants.Resources.mentalHealthResources
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("求助資源")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                    .padding(.leading, 16)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(resources) { resource in
                        MentalHealthResourceCard(
                            resource: resource,
                            onTap: {
                                handleResourceAction(resource.action)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingHotlineSheet) {
            HotlineDetailView(isPresented: $showingHotlineSheet)
        }
        .sheet(isPresented: $showingGuideSheet) {
            GuideDetailView(isPresented: $showingGuideSheet)
        }
        .sheet(isPresented: $showingTechniquesSheet) {
            TechniquesDetailView(isPresented: $showingTechniquesSheet)
        }
        .sheet(isPresented: $showingMapSheet) {
            MapDetailView(isPresented: $showingMapSheet)
        }
        .sheet(isPresented: $showingRelaxSheet) {
            RelaxTimerView()
        }
    }
    
    private func handleResourceAction(_ action: ResourceAction) {
        switch action {
        case .hotline:
            showingHotlineSheet = true
        case .guide:
            showingGuideSheet = true
        case .techniques:
            showingTechniquesSheet = true
        case .map:
            showingMapSheet = true
        case .relax:
            showingRelaxSheet = true
        }
    }
}

// MARK: - 心理測驗區塊
struct PsychologicalTestsSection: View {
    @State private var activeScale: ScaleMeta?
    @State private var showingRFQ8 = false
    @State private var showingTestGuide = false
    
    private let tests = HomeConstants.Tests.psychologicalTests
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("進一步瞭解自己")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                    .padding(.leading, 16)
                Spacer()
            }

            testGuideDisclosure
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(tests) { test in
                        PsychologicalTestCard(
                            test: test,
                            onTap: {
                                handleTestAction(test.action)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(item: $activeScale) { meta in
            ScaleTestView(meta: meta, isPresented: Binding(
                get: { activeScale != nil },
                set: { if !$0 { activeScale = nil } }
            ))
        }
        .sheet(isPresented: $showingRFQ8) {
            RFQ8TestView(isPresented: $showingRFQ8)
        }
    }
    
    private func handleTestAction(_ action: TestAction) {
        if action == .rfq8 {
            showingRFQ8 = true
            return
        }
        activeScale = HomeConstants.Tests.scaleMetaByAction[action]
    }

    private var testGuideDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingTestGuide.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.orange)
                    Text("測驗說明")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.titleColor)
                    Spacer()
                    Image(systemName: showingTestGuide ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppColors.lightBrown.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if showingTestGuide {
                VStack(alignment: .leading, spacing: 12) {
                    Text(HomeConstants.Tests.sharedOverviewText)
                        .font(.subheadline)
                        .foregroundColor(AppColors.titleColor.opacity(0.82))
                        .lineSpacing(5)

                    Divider()

                    Text(HomeConstants.Tests.sharedClosingText)
                        .font(.subheadline)
                        .foregroundColor(AppColors.titleColor.opacity(0.82))
                        .lineSpacing(5)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - 快捷入口區塊
struct QuickAccessSection: View {
    @State private var showingChat = false
    @State private var showingEmotionBox = false
    
    private let items: [QuickAccessItem] = [
        QuickAccessItem(
            title: "時光寶盒",
            subtitle: "整理情緒與收集力量",
            icon: "suitcase.fill",
            buttonText: "前往查看",
            destination: .emotionBox
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我的重要時刻")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                    .padding(.leading, 16)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        QuickAccessCard(item: item) {
                            handleDestination(item.destination)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingChat) {
            ChatListPage()
        }
        .sheet(isPresented: $showingEmotionBox) {
            NavigationView {
                ProfileView(openSupportReasonsOnAppear: true)
            }
        }
    }
    
    private func handleDestination(_ destination: QuickAccessDestination) {
        switch destination {
        case .chat:
            showingChat = true
        case .emotionBox:
            showingEmotionBox = true
        }
    }
}

private struct QuickAccessItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let buttonText: String
    let destination: QuickAccessDestination
}

private enum QuickAccessDestination {
    case chat
    case emotionBox
}

private struct QuickAccessCard: View {
    let item: QuickAccessItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundColor(AppColors.darkBrown)
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.darkBrown)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.darkBrown.opacity(0.7))
                        .multilineTextAlignment(.leading)
                    
                    Text(item.buttonText)
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
            .frame(width: 160, height: 140)
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
    VStack(spacing: 20) {
        MentalHealthResourcesSection()
        PsychologicalTestsSection()
        QuickAccessSection()
    }
    .background(AppColors.lightYellow)
}
