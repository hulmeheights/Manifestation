//
//  ShareSheet.swift
//  Lumen
//
//  The system share sheet, for handing the backup file to iCloud Drive, Mail,
//  AirDrop or anywhere else. SwiftUI's ShareLink can't take a file that is
//  created at the moment the button is pressed, which is what we're doing.
//

import SwiftUI
import UIKit

/// A file on its way to the share sheet. URL isn't Identifiable, and adding
/// that conformance to a standard-library type would be rude.
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
