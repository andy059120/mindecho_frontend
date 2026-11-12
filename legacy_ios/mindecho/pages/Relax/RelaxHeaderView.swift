//
//  RelaxHeaderView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI

struct RelaxHeaderView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("放鬆")
                .font(.title2.bold())
                .foregroundColor(AppColors.titleColor)
            Text("透過冥想與呼吸，放鬆身心")
                .font(.subheadline)
                .foregroundColor(AppColors.subtitleColor)
        }
        .padding(.top)
    }
}

#Preview {
    RelaxHeaderView()
}
