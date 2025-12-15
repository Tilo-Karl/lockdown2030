//
//  ContentView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = GameVM()
    @State private var viewRadius: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            primaryActionsSection

            mapSection

            interactionSection   // lives in CV+InteractionSection.swift

            eventLogSection      // lives in CV+EventLogSection.swift
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
        let hp = vm.myHpText
        let ap = vm.myApText

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
}

#Preview { ContentView() }
