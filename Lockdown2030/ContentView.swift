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
        VStack(spacing: 16) {
            // Header
            headerSection

            Divider()
                .padding(.vertical, 4)

            primaryActionsSection

            mapSection

            viewRadiusSection

            TileDetailsSection(vm: vm)
            EventLogSection(vm: vm)
            
            // Attack row
            //attackSection

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
}

// MARK: - Map & Info Sections
extension ContentView {
    fileprivate var mapSection: some View {
        Group {
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
        }
    }
}

// MARK: - Header & Controls
extension ContentView {
    fileprivate var headerSection: some View {
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

    fileprivate var viewRadiusSection: some View {
        HStack(spacing: 8) {
            Text("View radius: \(viewRadius)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("-") {
                if viewRadius < vm.maxViewRadius {
                    viewRadius += 1
                }
            }
            .buttonStyle(.bordered)

            Button("+") {
                if viewRadius > 0 {
                    viewRadius -= 1
                }
            }
            .buttonStyle(.bordered)
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
}

#Preview { ContentView() }
