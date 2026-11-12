import SwiftUI

// MARK: - 自訂認證輸入框組件
struct AuthTextField: View {
    
    // MARK: - 屬性
    let field: FormField
    @Binding var text: String
    let isValid: Bool
    let errorMessage: String
    let onEditingChanged: (Bool) -> Void
    let onCommit: () -> Void
    let placeholderOverride: String?
    let showValidationIcon: Bool
    let showPasswordStrength: Bool
    
    // MARK: - 內部狀態
    @State private var isSecureTextVisible = false
    @State private var isFocused = false
    @FocusState private var textFieldFocused: Bool
    
    // MARK: - 初始化
    init(
        field: FormField,
        text: Binding<String>,
        isValid: Bool = true,
        errorMessage: String = "",
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCommit: @escaping () -> Void = {},
        placeholderOverride: String? = nil,
        showValidationIcon: Bool = true,
        showPasswordStrength: Bool = true
    ) {
        self.field = field
        self._text = text
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
        self.placeholderOverride = placeholderOverride
        self.showValidationIcon = showValidationIcon
        self.showPasswordStrength = showPasswordStrength
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 標籤
            HStack {
                Text(placeholderOverride ?? field.placeholder)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(labelColor)
                
                Spacer()
                
                // 密碼強度指示器（僅用於密碼字段）
                if showPasswordStrength && field == .password && !text.isEmpty {
                    passwordStrengthIndicator
                }
            }
            
            // 輸入框容器
            HStack(spacing: 12) {
                // 輸入框
                if field.isSecure && !isSecureTextVisible {
                    SecureField(placeholderOverride ?? field.placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.darkBrown)
                } else {
                    TextField(placeholderOverride ?? field.placeholder, text: $text)
                        .keyboardType(field.keyboardType)
                        .textContentType(textContentType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled(true)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.darkBrown)
                }
                
                // 密碼可見性切換按鈕
                if field.isSecure {
                    passwordVisibilityButton
                }
                
                // 驗證狀態圖標
                validationIcon
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(backgroundColors)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .focused($textFieldFocused)
            .onChange(of: textFieldFocused) { focused in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = focused
                }
                onEditingChanged(focused)
            }
            .onSubmit {
                onCommit()
            }
            
            // 錯誤訊息
            if !isValid && !errorMessage.isEmpty {
                errorMessageView
            }
            
            // 輔助文字（僅用於特定字段）
            if field == .dateOfBirth && text.isEmpty {
                helperText
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isValid)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - 視圖組件
private extension AuthTextField {
    
    // 密碼強度指示器
    var passwordStrengthIndicator: some View {
        let strength = Validation.passwordStrength(text)
        
        return HStack(spacing: 4) {
            Text(strength.description)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(strength.color)
            
            // 強度條
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .frame(width: 12, height: 3)
                        .foregroundColor(
                            Double(index) < strength.progress * 3
                                ? strength.color
                                : Color.gray.opacity(0.3)
                        )
                }
            }
        }
    }
    
    // 密碼可見性切換按鈕
    var passwordVisibilityButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSecureTextVisible.toggle()
            }
        }) {
            Image(systemName: isSecureTextVisible ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mediumBrown)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 驗證狀態圖標
    var validationIcon: some View {
        Group {
            if showValidationIcon && !text.isEmpty {
                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isValid ? .green : .red)
                    .scaleEffect(isValid ? 1.0 : 1.1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isValid)
            }
        }
    }
    
    // 錯誤訊息視圖
    var errorMessageView: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.red)
            
            Text(errorMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.red)
            
            Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // 輔助文字
    var helperText: some View {
        Text("格式：YYYY-MM-DD")
            .font(.system(size: 12))
            .foregroundColor(AppColors.mediumBrown.opacity(0.7))
    }
}

// MARK: - 樣式計算屬性
private extension AuthTextField {
    
    // 標籤顏色
    var labelColor: Color {
        if !isValid && !text.isEmpty {
            return .red
        } else if isFocused {
            return AppColors.orange
        } else {
            return AppColors.darkBrown
        }
    }
    
    // 背景顏色
    var backgroundColors: some View {
        Group {
            if isFocused {
                AppColors.lightYellow
            } else if !isValid && !text.isEmpty {
                Color.red.opacity(0.05)
            } else {
                Color.white
            }
        }
    }
    
    // 邊框顏色
    var borderColor: Color {
        if !isValid && !text.isEmpty {
            return .red
        } else if isFocused {
            return AppColors.orange
        } else {
            return AppColors.lightBrown.opacity(0.5)
        }
    }
    
    // 邊框寬度
    var borderWidth: CGFloat {
        return isFocused ? 2 : 1
    }
    
    // 文字內容類型
    var textContentType: UITextContentType? {
        switch field {
        case .email:
            return .emailAddress
        case .password:
            return nil // 避免系統密碼自動填寫在預覽中攔截鍵盤
        case .confirmPassword:
            return nil // 避免系統密碼自動填寫在預覽中攔截鍵盤
        case .firstName:
            return .givenName
        case .lastName:
            return .familyName
        case .dateOfBirth:
            return .dateTime
        case .emergencyName:
            return .name
        case .emergencyRelation:
            return nil
        case .emergencyPhone:
            return .telephoneNumber
        case .supportContactName, .familyContactName:
            return .name
        case .supportContactInfo, .familyContactInfo:
            return .telephoneNumber
        }
    }
    
    // 自動大寫
    var autocapitalization: TextInputAutocapitalization {
        switch field {
        case .email:
            return .never
        case .password, .confirmPassword:
            return .never
        case .firstName, .lastName:
            return .words
        case .dateOfBirth:
            return .never
        case .emergencyName, .emergencyRelation:
            return .words
        case .emergencyPhone:
            return .never
        case .supportContactName, .familyContactName:
            return .words
        case .supportContactInfo, .familyContactInfo:
            return .never
        }
    }
}

// MARK: - 預覽
struct AuthTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AuthTextField(
                field: .email,
                text: .constant("test@example.com"),
                isValid: true
            )
            
            AuthTextField(
                field: .password,
                text: .constant("password123"),
                isValid: false,
                errorMessage: "密碼至少需要8個字符"
            )
            
            AuthTextField(
                field: .firstName,
                text: .constant(""),
                isValid: true
            )
        }
        .padding()
        .background(AppColors.lightYellow)
        .previewLayout(.sizeThatFits)
    }
}
