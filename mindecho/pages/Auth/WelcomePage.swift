import SwiftUI

// MARK: - 歡迎頁面
struct WelcomePage: View {
    
    // MARK: - 狀態管理
    @State private var currentPage = 0
    @State private var showLoginPage = false
    @State private var showRegisterPage = false
    @State private var showPrivacyPolicy = false
    @State private var animateContent = false
    @State private var animateButtons = false
    
    // MARK: - 常數
    private let welcomePages = WelcomePageData.pages
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // 背景漸變
                    backgroundGradient
                    
                    VStack(spacing: 0) {
                        // 內容區域
                        contentArea
                            .frame(height: geometry.size.height * 0.75)
                        
                        // 底部按鈕區域
                        bottomButtonArea
                            .frame(height: geometry.size.height * 0.25)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
            }
        }
        .fullScreenCover(isPresented: $showLoginPage) {
            LoginPage()
        }
        .fullScreenCover(isPresented: $showRegisterPage) {
            RegisterPage()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyStatementView()
        }
    }
}

// MARK: - 視圖組件
private extension WelcomePage {
    
    // 背景漸變
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.lightYellow,
                AppColors.lightYellow.opacity(0.8),
                Color.white
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    // 內容區域
    var contentArea: some View {
        VStack(spacing: 0) {
            // 頂部裝飾
            topDecoration
            
            // 分頁內容
            TabView(selection: $currentPage) {
                ForEach(0..<welcomePages.count, id: \.self) { index in
                    WelcomePageView(
                        page: welcomePages[index],
                        isActive: currentPage == index
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            // 自訂頁面指示器
            pageIndicator
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
    }
    
    // 頂部裝飾
    var topDecoration: some View {
        VStack(spacing: 8) {
            // MindEcho Logo
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.orange)
                
                Text("MindEcho")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.darkBrown)
            }
            .scaleEffect(animateContent ? 1 : 0.8)
            
            Text("心理健康的智慧夥伴")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mediumBrown)
                .opacity(animateContent ? 0.8 : 0)
        }
        .padding(.top, 50)
        .padding(.bottom, 20)
    }
    
    // 頁面指示器
    var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<welcomePages.count, id: \.self) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(
                        currentPage == index ? AppColors.orange : AppColors.lightBrown.opacity(0.5)
                    )
                    .scaleEffect(currentPage == index ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.vertical, 30) // 增加上下間距從 20 到 30
    }
    
    // 底部按鈕區域
    var bottomButtonArea: some View {
        VStack(spacing: 20) { // 增加按鈕之間的間距從 16 到 20
            // 主要按鈕
            AuthButton.primary(
                title: "立即登入",
                size: .large
            ) {
                showLoginPage = true
            }
            .opacity(animateButtons ? 1 : 0)
            .offset(y: animateButtons ? 0 : 20)
            
            // 次要按鈕
            AuthButton.text(
                title: "建立新帳號",
                size: .medium
            ) {
                showRegisterPage = true
            }
            .opacity(animateButtons ? 1 : 0)
            .offset(y: animateButtons ? 0 : 20)
            
            // 服務條款
            termsAndPrivacy
                .opacity(animateButtons ? 0.7 : 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 34) // 考慮 iPhone 底部安全區域
        .padding(.top, 20) // 增加頂部間距
    }
    
    // 服務條款和隱私政策
    var termsAndPrivacy: some View {
        VStack(spacing: 8) {
            Text("繼續即表示您同意我們的")
                .font(.system(size: 12))
                .foregroundColor(AppColors.mediumBrown.opacity(0.7))
            
            HStack(spacing: 16) {
                Button("服務條款") {
                    showPrivacyPolicy = true
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.orange)
                
                Text("和")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mediumBrown.opacity(0.7))
                
                Button("隱私政策") {
                    showPrivacyPolicy = true
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.orange)
            }
        }
    }
}

// MARK: - 動畫方法
private extension WelcomePage {
    
    func startAnimations() {
        // 內容動畫
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            animateContent = true
        }
        
        // 按鈕動畫
        withAnimation(.easeOut(duration: 0.6).delay(1.0)) {
            animateButtons = true
        }
    }
}

// MARK: - 單個歡迎頁面視圖
struct WelcomePageView: View {
    let page: WelcomePageItem
    let isActive: Bool
    
    @State private var imageScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // 插圖
            illustration
            
            // 文字內容
            textContent
        }
        .padding(.horizontal, 32)
        .onChange(of: isActive) { _, active in
            if active {
                animateContent()
            }
        }
        .onAppear {
            if isActive {
                animateContent()
            }
        }
    }
    
    private var illustration: some View {
        ZStack {
            // 背景圓圈
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            page.accentColor.opacity(0.1),
                            page.accentColor.opacity(0.05)
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
            
            // 主要圖標
            Image(systemName: page.systemImageName)
                .font(.system(size: 80, weight: .light))
                .foregroundColor(page.accentColor)
                .scaleEffect(imageScale)
        }
    }
    
    private var textContent: some View {
        VStack(spacing: 16) {
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.darkBrown)
                .multilineTextAlignment(.center)
                .opacity(textOpacity)
            
            Text(page.description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mediumBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(textOpacity)
        }
    }
    
    private func animateContent() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            imageScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            textOpacity = 1.0
        }
    }
}

// MARK: - 歡迎頁面數據模型
struct WelcomePageItem {
    let title: String
    let description: String
    let systemImageName: String
    let accentColor: Color
}

struct WelcomePageData {
    static let pages: [WelcomePageItem] = [
        WelcomePageItem(
            title: "專業心理支持",
            description: "基於認知行為療法(CBT)和正念療法(MBT)的專業對話，為您提供科學有效的心理健康指導",
            systemImageName: "heart.text.square",
            accentColor: AppColors.orange
        ),
        WelcomePageItem(
            title: "24/7 隨時陪伴",
            description: "無論何時何地，MindEcho 都在這裡傾聽您的心聲，提供即時的情感支持和專業建議",
            systemImageName: "clock.arrow.circlepath",
            accentColor: AppColors.mediumBrown
        ),
        WelcomePageItem(
            title: "隱私安全保護",
            description: "您的所有對話內容都經過端到端加密，我們承諾絕不會洩露您的個人隱私信息",
            systemImageName: "lock.shield",
            accentColor: AppColors.darkBrown
        ),
        WelcomePageItem(
            title: "個性化體驗",
            description: "AI 會學習您的偏好和需求，為您量身定制最適合的諮商方案和對話風格",
            systemImageName: "person.circle.fill",
            accentColor: AppColors.orange
        )
    ]
}

// MARK: - 預覽
struct WelcomePage_Previews: PreviewProvider {
    static var previews: some View {
        WelcomePage()
            .previewDisplayName("歡迎頁面")
        
        // 單個頁面預覽
        WelcomePageView(
            page: WelcomePageData.pages[0],
            isActive: true
        )
        .padding()
        .background(AppColors.lightYellow)
        .previewDisplayName("單個歡迎頁面")
        .previewLayout(.sizeThatFits)
    }
}
