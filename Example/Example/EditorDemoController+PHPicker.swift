import Foundation
import PhotosUI
import CoreServices
import AVFoundation


@available(iOS 14, *)
extension EditorDemoController: PHPickerViewControllerDelegate {

    func showPHPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 10
        configuration.filter = PHPickerFilter.any(of: [.images, .videos]);
        let viewController = PHPickerViewController(configuration: configuration)
        viewController.delegate = self
        present(viewController, animated: true, completion: nil)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        for result in results {
            print("ID: \(result.assetIdentifier ?? "")\n")
            print("Type Identifiers: \(result.itemProvider.registeredTypeIdentifiers)\n")
            let mediaTypesPriority: [String] = [AVFileType.heic.rawValue, kUTTypeJPEG as String, kUTTypeGIF as String, AVFileType.mp4.rawValue, AVFileType.mov.rawValue]
            for mediaType in mediaTypesPriority {
                if result.itemProvider.hasItemConformingToTypeIdentifier(mediaType) {
                    exportImage(in: result.itemProvider, forTypeIdentifier: mediaType)
                    break
                }
            }
            let videoTypesPriority: [String] = [AVFileType.mp4.rawValue, AVFileType.mov.rawValue]
            for mediaType in videoTypesPriority {
                if result.itemProvider.hasItemConformingToTypeIdentifier(mediaType) {
                    exportVideo(in: result.itemProvider, forTypeIdentifier: mediaType)
                    break
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }

    func exportImage(in item: NSItemProvider, forTypeIdentifier typeIdentifier: String) {
        item.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { (data, error) in
            guard let imageData = data, let image = UIImage(data: imageData) else {
                return
            }
            DispatchQueue.main.async {
                self.mediaInserter.insertImage(image)
            }
        }
    }

    func exportVideo(in item: NSItemProvider, forTypeIdentifier typeIdentifier: String) {
        item.loadInPlaceFileRepresentation(forTypeIdentifier: typeIdentifier) { (url, result, error) in
            guard let videoURL = url else {
                return
            }
            let fileCoordinator: NSFileCoordinator = NSFileCoordinator.init(filePresenter: nil)
            fileCoordinator.coordinate(readingItemAt: videoURL, options: [], error: nil) { (url) in
                let fileManager = FileManager.init()
                let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()+UUID().uuidString+".mp4")
                try? fileManager.copyItem(at: url, to: destinationURL)
                DispatchQueue.main.async {
                    self.mediaInserter.insertVideo(destinationURL)
                }
            }
        }
    }

}
