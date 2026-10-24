import SwiftUI

// MARK: - 按鈕樣式枚舉
enum AuthButtonStyle {
    case primary    // 主要按鈕（橘色背景）
    case secondary  // 次要按鈕（白色背景，橘色邊框）
    case text       // 文字按鈕（無背景）
    case danger     // 危險操作按鈕（紅色）
}

// MARK: - 按鈕大小枚舉
enum AuthButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 48
        case .large: return 56
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
    
    var padding: EdgeInsets {
        switch self {
        case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        }
    }
}

// MARK: - 自訂認證按鈕組件
struct AuthButton: View {
    
    // MARK: - 屬性
    let title: String
    let style: AuthButtonStyle
    let size: AuthButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    // MARK: - 內部狀態
    @State private var isPressed = false
    
    // MARK: - 初始化
    init(
        title: String,
        style: AuthButtonStyle = .primary,
        size: AuthButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                // 觸覺反饋
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                action()
            }
        }) {
            HStack(spacing: 8) {
                // 載入指示器
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                }
                
                // 按鈕文字
                Text(isLoading ? "載入中..." : title)
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(cornerRadius)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(buttonOpacity)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "載入中" : "")
        .accessibilityAddTraits(isDisabled ? .isButton : .isButton)
    }
}

// MARK: - 樣式計算屬性
private extension AuthButton {
    
    // 背景顏色
    var backgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.3)
        }
        
        switch style {
        case .primary:
            return isPressed ? AppColors.orange.opacity(0.8) : AppColors.orange
        case .secondary:
            return isPressed ? AppColors.lightYellow : Color.white
        case .text:
            return isPressed ? AppColors.lightYellow : Color.clear
        case .danger:
            return isPressed ? Color.red.opacity(0.8) : Color.red
        }
    }
    
    // 文字顏色
    var textColor: Color {
        if isDisabled {
            return Color.gray
        }
        
        switch style {
        case .primary:
            return Color.white
        case .secondary:
            return AppColors.orange
        case .text:
            return AppColors.orange
        case .danger:
            return Color.white
        }
    }
    
    // 邊框顏色
    var borderColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.3)
        }
        
        switch style {
        case .primary:
            return AppColors.orange
        case .secondary:
            return AppColors.orange
        case .text:
            return Color.clear
        case .danger:
            return Color.red
        }
    }
    
    // 邊框寬度
    var borderWidth: CGFloat {
        switch style {
        case .primary, .danger, .text:
            return 0
        case .secondary:
            return 2
        }
    }
    
    // 圓角半徑
    var cornerRadius: CGFloat {
        return 12
    }
    
    // 按鈕透明度
    var buttonOpacity: Double {
        return isDisabled ? 0.6 : 1.0
    }
}

// MARK: - 便利初始化方法
extension AuthButton {
    
    // 主要按鈕
    static func primary(
        title: String,
        size: AuthButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AuthButton {
        AuthButton(
            title: title,
            style: .primary,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    // 次要按鈕
    static func secondary(
        title: String,
        size: AuthButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AuthButton {
        AuthButton(
            title: title,
            style: .secondary,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    // 文字按鈕
    static func text(
        title: String,
        size: AuthButtonSize = .medium,
        action: @escaping () -> Void
    ) -> AuthButton {
        AuthButton(
            title: title,
            style: .text,
            size: size,
            isLoading: false,
            isDisabled: false,
            action: action
        )
    }
    
    // 危險操作按鈕
    static func danger(
        title: String,
        size: AuthButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> AuthButton {
        AuthButton(
            title: title,
            style: .danger,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
}

// MARK: - 載入按鈕 (特殊組件)
struct LoadingButton: View {
    let title: String
    let loadingTitle: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        loadingTitle: String = "載入中...",
        isLoading: Bool,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.loadingTitle = loadingTitle
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        AuthButton(
            title: isLoading ? loadingTitle : title,
            style: .primary,
            size: .large,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
}

// MARK: - 預覽
struct AuthButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 主要按鈕
            AuthButton.primary(
                title: "登入",
                size: .large
            ) {
                print("登入按鈕被點擊")
            }
            
            // 載入狀態的主要按鈕
            AuthButton.primary(
                title: "註冊",
                size: .large,
                isLoading: true
            ) {
                print("註冊按鈕被點擊")
            }
            
            // 次要按鈕
            AuthButton.secondary(
                title: "稍後再說",
                size: .medium
            ) {
                print("次要按鈕被點擊")
            }
            
            // 禁用狀態的按鈕
            AuthButton.primary(
                title: "提交",
                size: .medium,
                isDisabled: true
            ) {
                print("禁用按鈕被點擊")
            }
            
            // 文字按鈕
            AuthButton.text(
                title: "忘記密碼？",
                size: .small
            ) {
                print("文字按鈕被點擊")
            }
            
            // 危險操作按鈕
            AuthButton.danger(
                title: "刪除帳戶",
                size: .medium
            ) {
                print("危險按鈕被點擊")
            }
        }
        .padding()
        .background(AppColors.lightYellow)
        .previewLayout(.sizeThatFits)
    }
}
