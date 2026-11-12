//
//  RelaxTimerView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/30.
//

import SwiftUI

struct RelaxTimerView: View {
    @StateObject private var viewModel = RelaxTimerViewModel()
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 20) {
            RelaxHeaderView()
            RelaxModeSelector(viewModel: viewModel)
            
            ScrollView {
                VStack(spacing: 18) {
                    ForEach(viewModel.sections(for: viewModel.selectedMode)) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.headline)
                                .foregroundColor(AppColors.titleColor)
                            
                            ForEach(section.items) { item in
                                Button {
                                    openURL(item.url)
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(AppColors.orange.opacity(0.15))
                                                .frame(width: 64, height: 48)
                                            Image(systemName: "play.rectangle.fill")
                                                .foregroundColor(AppColors.orange)
                                                .font(.system(size: 20, weight: .semibold))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(item.title)
                                                .font(.headline)
                                                .foregroundColor(AppColors.titleColor)
                                                .lineLimit(2)
                                            Text("\(item.duration) ｜ \(item.topic)")
                                                .font(.subheadline)
                                                .foregroundColor(AppColors.titleColor.opacity(0.6))
                                                .lineLimit(2)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white.opacity(0.9))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(AppColors.lightBrown.opacity(0.4), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding()
        .background(AppColors.lightYellow.ignoresSafeArea())
    }
}

#Preview {
    RelaxTimerView()
}
