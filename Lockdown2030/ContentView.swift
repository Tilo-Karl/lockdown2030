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
            mapSection

            // Building info
            buildingInfoSection

            // View radius controls
            viewRadiusSection

            // Primary actions
            primaryActionsSection

            // Attack row
            attackSection

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

    private var mapSection: some View {
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
/*
    private var buildingInfoSection: some View {
        Group {
            if let pos = vm.myPos,
               let building = vm.buildingAt(x: pos.x, y: pos.y) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Building here")
                        .font(.subheadline)
                        .bold()

                    Text("Type: \(building.type)")
                        .font(.caption)

                    HStack(spacing: 8) {
                        Text("Floors: \(building.floors)")
                        Text("Tiles: \(building.tiles)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    Text("Root: (\(building.root.x), \(building.root.y))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
*/
    private var buildingInfoSection: some View {
        Group {
            if let pos = vm.myPos,
               let building = vm.buildingAt(x: pos.x, y: pos.y) {

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Building here")
                            .font(.subheadline)
                            .bold()

                        if vm.isInsideBuilding,
                           vm.activeBuildingId == building.id {
                            Text("Inside")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }

                    Text("Type: \(building.type)")
                        .font(.caption)

                    HStack(spacing: 12) {
                        Text("Floors: \(building.floors)")
                        Text("Tiles: \(building.tiles)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    Text("Root: (\(building.root.x), \(building.root.y))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Divider().padding(.vertical, 4)

                    // Enter / Exit button
                    Button(
                        vm.isInsideBuilding && vm.activeBuildingId == building.id
                        ? "Exit building"
                        : "Enter building"
                    ) {
                        if vm.isInsideBuilding && vm.activeBuildingId == building.id {
                            vm.leaveBuilding()
                        } else {
                            vm.enterBuildingHere()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(10)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
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

}

#Preview { ContentView() }
