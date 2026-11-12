import SwiftUI

struct MapDetailView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.titleColor)
                    
                    Text("附近心理診所")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                    
                    VStack(spacing: 16) {
                        ClinicCard(
                            name: "心安診所",
                            address: "台北市中正區重慶南路一段10號",
                            phone: "02-2388-1234",
                            specialties: ["憂鬱症", "焦慮症", "睡眠障礙"],
                            distance: "0.5公里"
                        )
                        
                        ClinicCard(
                            name: "康心身心科診所",
                            address: "台北市大安區敦化南路二段76號",
                            phone: "02-2325-5678",
                            specialties: ["心理諮商", "壓力管理", "人際關係"],
                            distance: "1.2公里"
                        )
                        
                        ClinicCard(
                            name: "樂活心理治療所",
                            address: "台北市信義區松高路11號8樓",
                            phone: "02-2722-9876",
                            specialties: ["認知行為治療", "家庭治療", "創傷治療"],
                            distance: "2.1公里"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🏥 就醫提醒")
                            .font(.headline)
                            .foregroundColor(AppColors.titleColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 建議事先電話預約")
                            Text("• 攜帶健保卡和身分證件")
                            Text("• 可準備相關病史和用藥紀錄")
                            Text("• 如需要可請家人陪同")
                        }
                        .font(.body)
                        .foregroundColor(AppColors.titleColor)
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                }
                .padding()
            }
            .background(AppColors.lightYellow)
            .navigationTitle("附近心理診所")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("關閉") { isPresented = false })
        }
    }
}

struct ClinicCard: View {
    let name: String
    let address: String
    let phone: String
    let specialties: [String]
    let distance: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    
                    Text(distance)
                        .font(.caption)
                        .foregroundColor(AppColors.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.orange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: {
                    if let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(AppColors.darkBrown)
                        .cornerRadius(8)
                }
            }
            
            Text(address)
                .font(.subheadline)
                .foregroundColor(AppColors.titleColor.opacity(0.7))
            
            Text("專長：\(specialties.joined(separator: "、"))")
                .font(.caption)
                .foregroundColor(AppColors.titleColor)
            
            HStack(spacing: 8) {
                Button(action: {
                    // 導航功能
                }) {
                    Text("導航")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.darkBrown)
                        .cornerRadius(6)
                }
                
                Button(action: {
                    // 預約功能
                }) {
                    Text("預約")
                        .font(.caption)
                        .foregroundColor(AppColors.titleColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppColors.titleColor, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

#Preview {
    MapDetailView(isPresented: .constant(true))
}
