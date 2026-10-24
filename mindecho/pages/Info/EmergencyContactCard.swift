//
//  EmergencyContactCard.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//
import SwiftUI

struct EmergencyContactCard: View {
    let title: String
    let subtitle: String
    let buttonText: String
    let phoneNumber: String
    
    @Environment(\.openURL) private var openURL
    
    private var dialableNumber: String {
        phoneNumber.filter { $0.isNumber || $0 == "+" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "lifepreserver")
                        .foregroundColor(.orange)
                        .font(.system(size: 15, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.brown)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
            }
            
            Spacer(minLength: 0)
            
            Button(action: {
                guard !dialableNumber.isEmpty,
                      let url = URL(string: "tel://\(dialableNumber)") else {
                    return
                }
                openURL(url)
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text(buttonText)
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.95),
                            Color.orange.opacity(0.75)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: Color.orange.opacity(0.25), radius: 8, y: 4)
            }
        }
        .padding(12)
        .frame(width: 170, height: 130, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
                .shadow(color: Color.orange.opacity(0.12), radius: 16, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.orange.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview{
    EmergencyContactCard(
        title: "title",
        subtitle: "subtitle",
        buttonText: "button",
        phoneNumber: "0912345678"
    )
}
