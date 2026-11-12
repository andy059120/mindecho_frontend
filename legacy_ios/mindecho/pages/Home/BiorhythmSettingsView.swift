import SwiftUI

struct BiorhythmSettingsView: View {
    @Binding var currentDate: Date
    @Binding var birthDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("請輸入日期")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("出生日期")
                                .font(.headline)
                                .foregroundColor(AppColors.titleColor)
                            
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .onChange(of: birthDate) { _ in
                                    saveBirthDate()
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("當前日期")
                                .font(.headline)
                                .foregroundColor(AppColors.titleColor)
                            
                            DatePicker("", selection: $currentDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                        }
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                    
                    Button("計算我的生理節律") {
                        isPresented = false
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.darkBrown)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("生理節律解讀")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.titleColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("身體生理節律 (23天)：影響身心的體力、耐力，以及身心和各種運動機能。")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.titleColor)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("情緒生理節律 (28天)：影響感性的情緒調節性，情緒控制穩定性，適合社交活動。")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.titleColor)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("智力生理節律 (33天)：影響理性的思維能力，邏輯推理，記憶力和學習能力。")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.titleColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(AppColors.titleColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                    
                    // 生理節律模式說明
                    VStack(alignment: .leading, spacing: 12) {
                        Text("使用說明")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.titleColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("標準模式:")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.titleColor)
                                Text("基於出生日期計算傳統生理節律")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.titleColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("個人模式:")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.titleColor)
                                Text("基於您的每日檢測數據分析個人規律")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.titleColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Text("💡 建議: 持續記錄每日檢測數據，個人模式會更準確。")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.orange)
                                .padding(.top, 4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(AppColors.lightYellow)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(AppColors.lightYellow)
            .navigationTitle("生理節律計算")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("✕") {
                    isPresented = false
                }
                .foregroundColor(AppColors.titleColor)
            )
        }
        .onAppear {
            loadBirthDate()
        }
    }
    
    // MARK: - 私有方法
    
    /// 載入存儲的出生日期
    private func loadBirthDate() {
        if let storedBirthDate = UserDefaults.standard.object(forKey: HomeConstants.UserDefaultsKeys.birthDate) as? Date {
            birthDate = storedBirthDate
        }
    }
    
    /// 保存出生日期
    private func saveBirthDate() {
        UserDefaults.standard.set(birthDate, forKey: HomeConstants.UserDefaultsKeys.birthDate)
    }
}

#Preview {
    BiorhythmSettingsView(
        currentDate: .constant(Date()),
        birthDate: .constant(Date()),
        isPresented: .constant(true)
    )
}
