//
//  RelaxModeSelector.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI

struct RelaxModeSelector: View {
    @ObservedObject var viewModel: RelaxTimerViewModel
    
    var body: some View {
        HStack {
            ForEach(RelaxTimerViewModel.Mode.allCases) { mode in
                Button {
                    viewModel.selectedMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(viewModel.selectedMode == mode ? AppColors.titleColor : AppColors.titleColor.opacity(0.6))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(viewModel.selectedMode == mode ? Color.white : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(AppColors.lightBrown.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.lightYellow.opacity(0.6))
        )
    }
}

#Preview {
    RelaxModeSelector(viewModel: RelaxTimerViewModel())
}
