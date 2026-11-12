import SwiftUI

struct HotlineDetailView: View {
    @Binding var isPresented: Bool

    private let sections: [ResourceSection] = [
        ResourceSection(
            title: "緊急求助專線",
            icon: "cross.case.fill",
            items: [
                .phone(title: "112 緊急救難專線", value: "112", description: "緊急救援與通報"),
                .phone(title: "119 消防局", value: "119", description: "火警、救護與緊急救援"),
                .phone(title: "110 警察局", value: "110", description: "治安事件與緊急報案")
            ]
        ),
        ResourceSection(
            title: "免費協談專線",
            icon: "phone.connection.fill",
            items: [
                .phone(title: "1925 衛生福利部安心專線", value: "1925", description: "24 小時心理支持與危機協談"),
                .phone(title: "1995 生命線", value: "1995", description: "24 小時免費心理諮詢服務"),
                .phone(title: "1980 張老師專線", value: "1980", description: "輔導與情緒支持"),
                .phone(title: "0800-788-995 安心專線", value: "0800788995", description: "心理健康諮詢服務"),
                .phone(title: "(02)2505-9595 台北市生命線自殺防治熱線", value: "0225059595", description: "自殺防治與危機支持"),
                .phone(title: "0800-001-769 踹貢少年專線", value: "0800001769", description: "青少年協談專線"),
                .phone(title: "(02)2369-2696 宇宙光關懷熱線", value: "0223692696", description: "免費協談與關懷支持"),
                .phone(title: "(02)2768-7733 觀音線", value: "0227687733", description: "免費協談與陪伴資源")
            ]
        ),
        ResourceSection(
            title: "心理諮商資源",
            icon: "brain.head.profile",
            items: [
                .link(title: "衛生福利部心理健康司", value: "https://dep.mohw.gov.tw/domhaoh/np-326-107.html", description: "官方心理健康與諮商資源"),
                .link(title: "心理諮商資源與求助管道", value: "https://www.gov.tw/News_Content_26_826198", description: "我的 E 政府整理的求助資訊"),
                .link(title: "全台各地輔導專線", value: "https://reurl.cc/EmQOEn", description: "各縣市輔導與求助窗口"),
                .link(title: "愛牽手專線（觀音線）", value: "https://www.kuanyin-line.org/empty_19718.php", description: "觀音線服務介紹與求助說明")
            ]
        ),
        ResourceSection(
            title: "社會福利資源",
            icon: "person.3.fill",
            items: [
                .phone(title: "113 社會局保護專線", value: "113", description: "家庭暴力、兒少與性侵害保護"),
                .phone(title: "0800-770-885 毒品危害防制中心諮詢專線", value: "0800770885", description: "毒品防制與戒治諮詢"),
                .phone(title: "0800-228-585 老朋友專線", value: "0800228585", description: "長者關懷與陪伴支持"),
                .phone(title: "0800-013-999 男性關懷專線", value: "0800013999", description: "男性情緒與生活支持"),
                .phone(title: "165 反詐騙諮詢專線", value: "165", description: "詐騙通報與諮詢"),
                .phone(title: "1957 社福專線", value: "1957", description: "社會福利與急難救助諮詢")
            ]
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView

                    ForEach(sections) { section in
                        ResourceSectionView(section: section)
                    }

                    reminderView
                }
                .padding()
            }
            .background(AppColors.lightYellow)
            .navigationTitle("心理諮詢熱線")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("關閉") { isPresented = false })
        }
    }
}

private extension HotlineDetailView {
    var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "phone.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.titleColor)

            Text("24 小時心理諮詢與求助資源")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.titleColor)

            Text("遇到危急情況請優先撥打 112、119 或 110，其他專線與網站可依需求尋求協助。")
                .font(.body)
                .foregroundColor(AppColors.titleColor.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }

    var reminderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("使用提醒")
                .font(.headline)
                .foregroundColor(AppColors.titleColor)

            Text("• 如有立即危險，請先聯絡緊急救援單位")
            Text("• 大多數專線提供匿名或保密協談服務")
            Text("• 網站資源可提供更多地區性諮商與轉介資訊")
        }
        .font(.body)
        .foregroundColor(AppColors.titleColor)
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

private struct ResourceSectionView: View {
    let section: ResourceSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .foregroundColor(AppColors.titleColor)
                Text(section.title)
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
            }

            ForEach(section.items) { item in
                ResourceCard(item: item)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

private struct ResourceCard: View {
    let item: ResourceItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.kind == .phone ? "phone.fill" : "link")
                .font(.title3)
                .foregroundColor(AppColors.titleColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)

                Text(item.description)
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))

                Text(item.value)
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.75))
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer()

            Button(action: openResource) {
                Text(item.kind == .phone ? "撥打" : "開啟")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColors.darkBrown)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.55))
        .cornerRadius(10)
    }

    private func openResource() {
        let urlString: String
        switch item.kind {
        case .phone:
            urlString = "tel:\(item.value.filter(\.isNumber))"
        case .link:
            urlString = item.value
        }

        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct ResourceSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let items: [ResourceItem]
}

private struct ResourceItem: Identifiable {
    enum Kind {
        case phone
        case link
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let value: String
    let description: String

    static func phone(title: String, value: String, description: String) -> ResourceItem {
        ResourceItem(kind: .phone, title: title, value: value, description: description)
    }

    static func link(title: String, value: String, description: String) -> ResourceItem {
        ResourceItem(kind: .link, title: title, value: value, description: description)
    }
}

#Preview {
    HotlineDetailView(isPresented: .constant(true))
}
