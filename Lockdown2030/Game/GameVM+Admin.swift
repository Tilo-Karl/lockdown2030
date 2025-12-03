//
//  GameVM+Admin.swift
//  Lockdown2030
//
//  Created by Tilo Delau on 2025-11-17.
//

import Foundation

extension GameVM {
  @MainActor
  func adminUploadGameConfig() async {
    // One-shot admin helper: load a JSON file from the bundle and overwrite the game config doc.
    guard let url = Bundle.main.url(forResource: "lockdown2030-gameConfig", withExtension: "json") else {
      log.error("Admin config upload failed: missing lockdown2030-gameConfig.json in bundle")
      return
    }

    do {
      let data = try Data(contentsOf: url)
      guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
        log.error("Admin config upload failed: JSON is not a [String: Any] dictionary")
        return
      }

      guard let ref = gameDocRef else {
        log.error("Admin config upload failed: missing gameDocRef")
        return
      }

      try await ref.setData(json, merge: false)

      log.info("Admin config uploaded successfully ✅")
    } catch {
      log.error("Admin config upload error: \(String(describing: error))")
    }
  }
}
