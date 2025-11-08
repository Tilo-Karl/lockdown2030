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
            VStack(spacing: 4) {
                Text(vm.gameName.isEmpty ? "Lockdown 2030 MVP" : vm.gameName)
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

            // Actions
            HStack(spacing: 12) {
                Button("Join") { Task { await vm.joinGame() } }
                    .buttonStyle(.borderedProminent)
                Button("Up")    { Task { await vm.move(dx: 0,  dy: -1) } }
                Button("Down")  { Task { await vm.move(dx: 0,  dy:  1) } }
                Button("Left")  { Task { await vm.move(dx: -1, dy:  0) } }
                Button("Right") { Task { await vm.move(dx: 1,  dy:  0) } }
            }
            .buttonStyle(.bordered)

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

            Button("Create/Update My Player") { vm.upsertMyPlayer() }
                .buttonStyle(.bordered)

            Divider()
                .padding(.vertical, 8)

            // Show the map once we have a user and game dimensions
            if !vm.uid.isEmpty && vm.gridW > 0 && vm.gridH > 0 {
                GridView(vm: vm)
                    .padding(.top, 8)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
    }
}

#Preview { ContentView() }

