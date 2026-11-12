import SwiftUI

// MARK: - 載入視圖樣式
enum LoadingStyle {
    case dots       // 點狀載入動畫
    case spinner    // 旋轉動畫
    case pulse      // 脈衝動畫
    case wave       // 波浪動畫
}

// MARK: - 主要載入視圖組件
struct AuthLoadingView: View {
    let style: LoadingStyle
    let size: CGFloat
    let color: Color
    let message: String?
    
    init(
        style: LoadingStyle = .dots,
        size: CGFloat = 40,
        color: Color = AppColors.orange,
        message: String? = nil
    ) {
        self.style = style
        self.size = size
        self.color = color
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 載入動畫
            Group {
                switch style {
                case .dots:
                    DotsLoadingView(size: size, color: color)
                case .spinner:
                    SpinnerLoadingView(size: size, color: color)
                case .pulse:
                    PulseLoadingView(size: size, color: color)
                case .wave:
                    WaveLoadingView(size: size, color: color)
                }
            }
            
            // 載入訊息
            if let message = message {
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mediumBrown)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - 點狀載入動畫
struct DotsLoadingView: View {
    let size: CGFloat
    let color: Color
    
    @State private var animationAmounts = [0.0, 0.0, 0.0]
    
    var body: some View {
        HStack(spacing: size * 0.2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: size * 0.25, height: size * 0.25)
                    .foregroundColor(color)
                    .scaleEffect(1.0 + animationAmounts[index])
                    .opacity(0.3 + (animationAmounts[index] * 0.7))
            }
        }
        .onAppear {
            startDotsAnimation()
        }
    }
    
    private func startDotsAnimation() {
        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                ) {
                    animationAmounts[index] = 1.0
                }
            }
        }
    }
}

// MARK: - 旋轉載入動畫
struct SpinnerLoadingView: View {
    let size: CGFloat
    let color: Color
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [color.opacity(0.1), color]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.0)
                        .repeatForever(autoreverses: false)
                ) {
                    rotationAngle = 360
                }
            }
    }
}

// MARK: - 脈衝載入動畫
struct PulseLoadingView: View {
    let size: CGFloat
    let color: Color
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // 外層脈衝圈
            Circle()
                .frame(width: size, height: size)
                .foregroundColor(color.opacity(0.2))
                .scaleEffect(scale)
                .opacity(1 - scale + 0.5)
            
            // 內層核心圈
            Circle()
                .frame(width: size * 0.6, height: size * 0.6)
                .foregroundColor(color)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
            ) {
                scale = 1.2
            }
            
            withAnimation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
            ) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - 波浪載入動畫
struct WaveLoadingView: View {
    let size: CGFloat
    let color: Color
    
    @State private var waveOffsets = [0.0, 0.0, 0.0, 0.0]
    
    var body: some View {
        HStack(spacing: size * 0.1) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: size * 0.1)
                    .frame(width: size * 0.15, height: size * 0.6)
                    .foregroundColor(color)
                    .offset(y: waveOffsets[index])
            }
        }
        .onAppear {
            startWaveAnimation()
        }
    }
    
    private func startWaveAnimation() {
        for index in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    waveOffsets[index] = -size * 0.2
                }
            }
        }
    }
}

// MARK: - 全屏載入覆蓋層
struct LoadingOverlay: View {
    let isVisible: Bool
    let message: String?
    let style: LoadingStyle
    
    init(
        isVisible: Bool,
        message: String? = "載入中...",
        style: LoadingStyle = .dots
    ) {
        self.isVisible = isVisible
        self.message = message
        self.style = style
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                // 半透明背景
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // 防止點擊穿透
                    }
                
                // 載入內容卡片
                VStack(spacing: 20) {
                    AuthLoadingView(
                        style: style,
                        size: 50,
                        color: AppColors.orange,
                        message: message
                    )
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 50)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
            .zIndex(999) // 確保在最上層
        }
    }
}

// MARK: - 內聯載入視圖 (用於按鈕等小組件)
struct InlineLoadingView: View {
    let isLoading: Bool
    let size: CGFloat
    let color: Color
    
    init(
        isLoading: Bool,
        size: CGFloat = 16,
        color: Color = AppColors.orange
    ) {
        self.isLoading = isLoading
        self.size = size
        self.color = color
    }
    
    var body: some View {
        if isLoading {
            SpinnerLoadingView(size: size, color: color)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
        }
    }
}

// MARK: - 骨架屏載入效果
struct SkeletonLoadingView: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var shimmerOffset: CGFloat = -200
    
    init(
        width: CGFloat = 200,
        height: CGFloat = 20,
        cornerRadius: CGFloat = 8
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppColors.lightBrown.opacity(0.3))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Color.white.opacity(0.8),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .clipped()
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = width + 200
                }
            }
    }
}

// MARK: - 便利的 View 擴展
extension View {
    func loadingOverlay(
        isVisible: Bool,
        message: String? = "載入中...",
        style: LoadingStyle = .dots
    ) -> some View {
        ZStack {
            self
            LoadingOverlay(
                isVisible: isVisible,
                message: message,
                style: style
            )
        }
    }
}

// MARK: - 預覽
struct AuthLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // 不同樣式的載入動畫
            AuthLoadingView(style: .dots, message: "載入中...")
            AuthLoadingView(style: .spinner, message: "處理中...")
            AuthLoadingView(style: .pulse, message: "同步中...")
            AuthLoadingView(style: .wave, message: "上傳中...")
            
            // 骨架屏效果
            VStack(alignment: .leading, spacing: 10) {
                SkeletonLoadingView(width: 150, height: 20)
                SkeletonLoadingView(width: 200, height: 16)
                SkeletonLoadingView(width: 100, height: 16)
            }
        }
        .padding()
        .background(AppColors.lightYellow)
        .previewLayout(.sizeThatFits)
    }
}
