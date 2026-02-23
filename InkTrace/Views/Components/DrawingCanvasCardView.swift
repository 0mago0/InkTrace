//
//  DrawingCanvasCardView.swift
//  InkTrace
//

import SwiftUI
import PencilKit

struct DrawingCanvasCardView: View {
    @Binding var pkDrawing: PKDrawing
    @Binding var simpleStrokes: [[StrokePoint]]
    @Binding var currentSimpleStroke: [StrokePoint]
    @Binding var brushWidth: CGFloat
    @Binding var usePencilKit: Bool
    let canvasScale: CGFloat
    let previewCharacter: String?
    let onUndoManagerReady: (UndoManager?) -> Void

    var body: some View {
        ZStack {
            if usePencilKit {
                PKCanvasViewWrapper(drawing: $pkDrawing, lineWidth: $brushWidth, onUndoManagerReady: onUndoManagerReady)
                    .frame(width: 300, height: 300)
                    .clipped()
                    .overlay(canvasOverlay)
            } else {
                SimpleDrawingView(strokes: $simpleStrokes, currentStroke: $currentSimpleStroke, lineWidth: $brushWidth)
                    .frame(width: 300, height: 300)
                    .clipped()
                    .overlay(canvasOverlay)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        .scaleEffect(canvasScale)
    }

    @ViewBuilder
    private var canvasOverlay: some View {
        ZStack {
            if let previewCharacter {
                Text(previewCharacter)
                    .font(previewFont(for: previewCharacter))
                    .foregroundColor(.black.opacity(0.08))
                    .minimumScaleFactor(0.1)
                    .lineLimit(1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            Rectangle()
                .stroke(Color(UIColor.separator), lineWidth: 1)
            Crosshair(size: CGSize(width: 300, height: 300), lineColor: Color(UIColor.separator), lineWidth: 1, dash: [4, 4])
        }
    }

    /// 根據字符選擇字體：英文/拉丁用 Inter，其餘（中文等）用 Noto Sans TC
    private func previewFont(for character: String) -> Font {
        let isLatin = character.unicodeScalars.allSatisfy { $0.value < 0x0250 }
        return isLatin
            ? .custom("Inter-Regular", size: 220)
            : .custom("NotoSansTC-Regular", size: 220)
    }
}
