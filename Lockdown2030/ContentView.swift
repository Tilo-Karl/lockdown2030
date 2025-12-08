//
//  ContentView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = GameVM()
    @State private var targetUid: String = ""
    @State private var viewRadius: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            //Divider()
             //   .padding(.vertical, 4)

            primaryActionsSection

            mapSection

            interactionSection

            chatSection

            // Attack row
            //attackSection
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
        .onChange(of: vm.maxViewRadius) { newValue in
            if viewRadius > newValue {
                viewRadius = newValue
            }
        }
    }
}

// MARK: - Map & Info Sections
extension ContentView {
    fileprivate var mapSection: some View {
        Group {
            if !vm.uid.isEmpty && vm.gridW > 0 && vm.gridH > 0 {
                GridView(vm: vm, viewRadius: viewRadius)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .overlay(
                        Rectangle()
                            .stroke(Color.red.opacity(0.9), lineWidth: 1)
                    )
                 
            } else {
                Text("Join a game to see the map.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Header & Controls
extension ContentView {
    fileprivate var headerSection: some View {
        let hp = vm.myPlayer?.hp ?? 0
        let ap = vm.myPlayer?.ap ?? 0

        return VStack(spacing: 4) {
            Text(vm.gameName.isEmpty ? "Lockdown 2030" : vm.gameName)
                .font(.title2).bold()
            
            Text("Status: \(vm.status) • \(vm.gridW)x\(vm.gridH) • R\(vm.maxViewRadius)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("❤️")
                    Text("\(hp) HP")
                }
                HStack(spacing: 4) {
                    Text("⚡️")
                    Text("\(ap) AP")
                }
            }
            .font(.caption)
            
            if !vm.uid.isEmpty {
                Text("UID: \(vm.uid)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let p = vm.myPos {
                Text("You: (\(p.x), \(p.y))")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
    }

    fileprivate var primaryActionsSection: some View {
        HStack(spacing: 12) {
            Button("Join") {
                Task { await vm.joinGame() }
            }
            .buttonStyle(.borderedProminent)

            Button("Create / Update My Player") {
                vm.upsertMyPlayer()
            }
            .buttonStyle(.bordered)
        }
    }

    fileprivate var interactionSection: some View {
        Group {
            if let pos = vm.interactionPos, let kind = vm.interactionKind {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(interactionTitle(for: kind))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("(\(pos.x), \(pos.y))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Simple description placeholder for now.
                    Text(interactionDescription(for: kind))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Spacer()
                        Button(interactionButtonLabel(for: kind)) {
                            switch kind {
                            case .zombie:
                                vm.attackSelected()
                            case .tile, .human, .item:
                                // No concrete actions yet for these kinds.
                                break
                            }
                        }
                        .buttonStyle(.bordered)
                        // For now, only attacks on zombies are actionable.
                        .disabled(kind != .zombie)
                    }
                }
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.top, 4)
            }
        }
    }

    fileprivate var chatSection: some View {
        VStack(spacing: 4) {
            // Title / label
            HStack {
                Text("Radio / Chat")
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

    fileprivate var attackSection: some View {
        HStack(spacing: 12) {
            TextField("target uid…", text: $targetUid)
                .textFieldStyle(.roundedBorder)

            Button("Attack") {
                let t = targetUid.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { return }
                Task { await vm.attack(target: t) }
            }
            .buttonStyle(.bordered)
        }
    }

    private func interactionTitle(for kind: GameVM.InteractionKind) -> String {
        switch kind {
        case .tile:   return "Tile"
        case .zombie: return "Zombie"
        case .human:  return "Human"
        case .item:   return "Item"
        }
    }

    private func interactionDescription(for kind: GameVM.InteractionKind) -> String {
        switch kind {
        case .tile:
            return "You are standing here."
        case .zombie:
            return "Zombie on your tile. Future: inspect and attack."
        case .human:
            return "Human on your tile. Future: talk / inspect."
        case .item:
            return "Item on your tile. Future: pick up."
        }
    }

    private func interactionButtonLabel(for kind: GameVM.InteractionKind) -> String {
        switch kind {
        case .tile:   return "Use tile"
        case .zombie: return "Attack"
        case .human:  return "Talk"
        case .item:   return "Pick up"
        }
    }

    private func renderedMessageText(_ msg: GameVM.GameMessage) -> String {
        switch msg.kind {
        case .system:
            return "[System] \(msg.text)"
        case .combat:
            return "[Combat] \(msg.text)"
        case .radio:
            return "[Radio] \(msg.text)"
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

#Preview { ContentView() }
