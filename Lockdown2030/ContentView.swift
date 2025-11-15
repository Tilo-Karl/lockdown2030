//
//  ContentView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameVM()
    @State private var targetUid: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection

            Divider()
                .padding(.vertical, 4)

            // Map
            if !vm.uid.isEmpty && vm.gridW > 0 && vm.gridH > 0 {
                GridView(vm: vm)
                    .padding(.top, 4)
                    .frame(minHeight: 220)
            } else {
                Text("Join a game to see the map.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 40)
            }

            // Primary actions
            primaryActionsSection

            // Attack row
            attackSection

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(vm.gameName.isEmpty ? "Lockdown 2030" : vm.gameName)
                .font(.title2).bold()

            Text("Status: \(vm.status) • \(vm.gridW)x\(vm.gridH)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

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

    private var primaryActionsSection: some View {
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

    private var attackSection: some View {
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
}

#Preview { ContentView() }

