//
//  GridView.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-08.
//

import SwiftUI

struct GridView: View {
    @ObservedObject var vm: GameVM
    @State private var lastTap: Pos? = nil

    var body: some View {
        VStack(spacing: 12) {
            Text("\(vm.gameName) • \(vm.gridW)x\(vm.gridH)")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 20)), count: vm.gridW), spacing: 2) {
                ForEach(0..<vm.gridW * vm.gridH, id: \.self) { index in
                    let x = index % vm.gridW
                    let y = index / vm.gridW
                    let isMe = (vm.myPos?.x == x && vm.myPos?.y == y)

                    ZStack {
                        // base cell
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))

                        // blue overlay for my current position
                        if isMe {
                            Rectangle()
                                .fill(Color.blue.opacity(0.6))
                        }
                    }
                    .frame(width: 30, height: 30)
                    .border(Color.gray.opacity(0.3), width: 0.5)
                    .onTapGesture {
                        handleTap(Pos(x: x, y: y))
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .padding()
    }

    private func handleTap(_ pos: Pos) {
        Task {
            if let last = lastTap, abs(pos.x - last.x) + abs(pos.y - last.y) == 1 {
                await vm.move(dx: pos.x - last.x, dy: pos.y - last.y)
            }
            lastTap = pos
        }
    }
}
