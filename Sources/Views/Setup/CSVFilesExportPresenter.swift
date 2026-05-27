//
//  CSVFilesExportPresenter.swift
//  HotTub Buddy
//

import SwiftUI
import UIKit

struct CSVFilesExportPresenter: UIViewControllerRepresentable {
    let fileURL: URL
    let onComplete: (Result<URL, Error>) -> Void

    func makeUIViewController(context: Context) -> CSVExportHostViewController {
        let host = CSVExportHostViewController()
        host.exportURL = fileURL
        host.onComplete = { result in
            context.coordinator.finish(with: result)
        }
        return host
    }

    func updateUIViewController(_ uiViewController: CSVExportHostViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    final class Coordinator {
        let onComplete: (Result<URL, Error>) -> Void
        private var didFinish = false

        init(onComplete: @escaping (Result<URL, Error>) -> Void) {
            self.onComplete = onComplete
        }

        func finish(with result: Result<URL, Error>) {
            guard !didFinish else { return }
            didFinish = true
            onComplete(result)
        }
    }
}

/// Presents the system export picker modally so iOS shows the real “Save as” export UI.
final class CSVExportHostViewController: UIViewController, UIDocumentPickerDelegate {
    var exportURL: URL!
    var onComplete: ((Result<URL, Error>) -> Void)!

    private var didPresentPicker = false
    private var didFinish = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPresentPicker else { return }
        didPresentPicker = true

        let picker = UIDocumentPickerViewController(forExporting: [exportURL], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.modalPresentationStyle = .formSheet
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            let result = urls.first.map { Result<URL, Error>.success($0) }
                ?? .failure(CocoaError(.userCancelled))
            self.complete(with: result)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.complete(with: .failure(CocoaError(.userCancelled)))
        }
    }

    private func complete(with result: Result<URL, Error>) {
        guard !didFinish else { return }
        didFinish = true
        dismiss(animated: true) {
            self.onComplete(result)
        }
    }
}

enum CSVBackupFileWriter {
    static func writeTemporaryCSV(text: String, filename: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent(filename, isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        guard let data = text.data(using: .utf8), !data.isEmpty else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}
