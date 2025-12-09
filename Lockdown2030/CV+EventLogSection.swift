//
//  CV+EventLogSection.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-12-09.
//

import SwiftUI

extension ContentView {
    var eventLogSection: some View {
        VStack(spacing: 4) {
            // Title / label
            HStack {
                Text("🛈 Event Log")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Messages area – unified log (system / combat / radio)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(vm.messageLog) { msg in
                            Text(renderedMessageText(msg))
                                .font(.caption2)
                                .foregroundStyle(messageColor(for: msg.kind))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(msg.id)   // needed for scrollTo
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: vm.messageLog.count) { _ in
                    if let lastId = vm.messageLog.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            // Input bar (non-functional placeholder)
            HStack(spacing: 8) {
                TextField("Type message…", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                Button {
                    // no-op for now
                } label: {
                    Text("Send")
                }
                .buttonStyle(.bordered)
                .disabled(true)
            }
            .font(.caption2)
        }
        .padding(8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .frame(maxHeight: 160) // fixed-ish height so only this scrolls
    }

    // MARK: - Log helpers

    private func renderedMessageText(_ msg: GameVM.GameMessage) -> String {
        switch msg.kind {
        case .system:
            return "🛈 \(msg.text)"
        case .combat:
            return "⚔️ \(msg.text)"
        case .radio:
            return "📱 \(msg.text)"
        }
    }

    private func messageColor(for kind: GameVM.GameMessage.Kind) -> Color {
        switch kind {
        case .system:
            return .secondary
        case .combat:
            return .red
        case .radio:
            return .primary
        }
    }
}
