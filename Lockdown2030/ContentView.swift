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
    @State private var viewRadius: Int = 1

    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection

            Divider()
                .padding(.vertical, 4)

            // Map
            if !vm.uid.isEmpty && vm.gridW > 0 && vm.gridH > 0 {
                GridView(vm: vm, viewRadius: viewRadius)
                    .padding(.top, 4)
                    .frame(minHeight: 220)
            } else {
                Text("Join a game to see the map.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 40)
            }

            // View radius controls
            viewRadiusSection

            // Primary actions
            primaryActionsSection

            // Attack row
            attackSection

            #if DEBUG
            adminSection
            #endif

            Spacer(minLength: 0)
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
        .onChange(of: vm.maxViewRadius) { newValue in
            if viewRadius > newValue {
                viewRadius = newValue
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(vm.gameName.isEmpty ? "Lockdown 2030" : vm.gameName)
                .font(.title2).bold()

            Text("Status: \(vm.status) • \(vm.gridW)x\(vm.gridH) • R\(vm.maxViewRadius)")
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

    private var viewRadiusSection: some View {
        HStack(spacing: 8) {
            Text("View radius: \(viewRadius)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // "-" = zoom out (show more tiles)
            Button("-") {
                if viewRadius < vm.maxViewRadius {
                    viewRadius += 1
                }
            }
            .buttonStyle(.bordered)

            // "+" = zoom in (show fewer tiles)
            Button("+") {
                if viewRadius > 0 {
                    viewRadius -= 1
                }
            }
            .buttonStyle(.bordered)
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

    #if DEBUG
    private var adminSection: some View {
        HStack(spacing: 12) {
            Button("Upload game config") {
                Task {
                    await vm.adminUploadGameConfig()
                }
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
    }
    #endif
}

#Preview { ContentView() }
