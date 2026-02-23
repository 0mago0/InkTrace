//
//  DrawingTopBarView.swift
//  InkTrace
//

import SwiftUI

struct DrawingTopBarView: View {
    @Binding var showPreviewCharacter: Bool
    let onSettingsTap: () -> Void
    let onHelpTap: () -> Void
    let onProgressTap: () -> Void

    var body: some View {
        HStack {
            CircleButton(icon: "gearshape.fill", action: onSettingsTap)

            Spacer()

            CircleButton(
                icon: showPreviewCharacter ? "eye.fill" : "eye.slash.fill",
                action: { showPreviewCharacter.toggle() }
            )
            CircleButton(icon: "questionmark.circle", action: onHelpTap)
            CircleButton(icon: "chart.bar.xaxis", action: onProgressTap)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

private struct CircleButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primary)
                .padding(10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(Circle())
        }
    }
}
