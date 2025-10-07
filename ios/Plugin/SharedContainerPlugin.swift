import Capacitor
import Foundation

@objc(SharedContainerPlugin)
public class SharedContainerPlugin: CAPPlugin {

    @objc func readSharedContainerDirectory(_ call: CAPPluginCall) {
        guard let path = call.getString("path") else {
            call.reject("Path parameter is required")
            return
        }

        // Get the shared container URL
        guard
            let sharedContainerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.soundsstudios.wave"
            )
        else {
            call.reject("Failed to get shared container URL")
            return
        }

        let fullPath = sharedContainerURL.appendingPathComponent(path)

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: fullPath,
                includingPropertiesForKeys: [
                    .nameKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey,
                ], options: [])

            // Filter out old files (older than 24 hours) and very large files (>500MB)
            let maxFileSize: Int64 = 500 * 1024 * 1024  // 500MB
            let maxAge: TimeInterval = 24 * 60 * 60  // 24 hours
            let cutoffDate = Date().addingTimeInterval(-maxAge)

            let fileList = contents.compactMap { url -> [String: Any]? in
                let fileName = url.lastPathComponent

                // Get file attributes
                guard
                    let attributes = try? url.resourceValues(forKeys: [
                        .fileSizeKey, .creationDateKey, .contentModificationDateKey,
                    ])
                else {
                    return nil
                }

                let fileSize = Int64(attributes.fileSize ?? 0)
                let creationDate = attributes.creationDate ?? Date.distantPast
                let modificationDate = attributes.contentModificationDate ?? Date.distantPast

                // Filter out files that are too large
                if fileSize > maxFileSize {
                    print("⚠️ Skipping large file: \(fileName) (\(fileSize) bytes)")
                    return nil
                }

                // Filter out old files
                let mostRecentDate = max(creationDate, modificationDate)
                if mostRecentDate < cutoffDate {
                    print(
                        "⚠️ Skipping old file: \(fileName) (created: \(creationDate), modified: \(modificationDate))"
                    )
                    return nil
                }

                return [
                    "name": fileName,
                    "size": fileSize,
                    "creationDate": ISO8601DateFormatter().string(from: creationDate),
                    "modificationDate": ISO8601DateFormatter().string(from: modificationDate),
                ]
            }

            call.resolve([
                "files": fileList
            ])
        } catch {
            call.reject("Failed to read directory: \(error.localizedDescription)")
        }
    }

    @objc func readSharedContainerFile(_ call: CAPPluginCall) {
        guard let path = call.getString("path") else {
            call.reject("Path parameter is required")
            return
        }

        // Get the shared container URL
        guard
            let sharedContainerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.soundsstudios.wave"
            )
        else {
            call.reject("Failed to get shared container URL")
            return
        }

        let fullPath = sharedContainerURL.appendingPathComponent(path)

        do {
            // Check file size first to avoid memory issues
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullPath.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0

            // Limit file size to 100MB to prevent memory crashes
            let maxFileSize: Int64 = 100 * 1024 * 1024  // 100MB
            if fileSize > maxFileSize {
                call.reject(
                    "File too large: \(fileSize) bytes. Maximum allowed: \(maxFileSize) bytes")
                return
            }

            let data = try Data(contentsOf: fullPath)
            let base64String = data.base64EncodedString()

            call.resolve([
                "data": base64String
            ])
        } catch {
            call.reject("Failed to read file: \(error.localizedDescription)")
        }
    }

    @objc func writeSharedContainerFile(_ call: CAPPluginCall) {
        guard let path = call.getString("path") else {
            call.reject("Path parameter is required")
            return
        }

        guard let data = call.getString("data") else {
            call.reject("Data parameter is required")
            return
        }

        // Get the shared container URL
        guard
            let sharedContainerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.soundsstudios.wave"
            )
        else {
            call.reject("Failed to get shared container URL")
            return
        }

        let fullPath = sharedContainerURL.appendingPathComponent(path)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: fullPath.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        do {
            guard let fileData = Data(base64Encoded: data) else {
                call.reject("Invalid base64 data")
                return
            }

            try fileData.write(to: fullPath)
            call.resolve()
        } catch {
            call.reject("Failed to write file: \(error.localizedDescription)")
        }
    }

    @objc func deleteSharedContainerFile(_ call: CAPPluginCall) {
        guard let path = call.getString("path") else {
            call.reject("Path parameter is required")
            return
        }

        // Get the shared container URL
        guard
            let sharedContainerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.soundsstudios.wave"
            )
        else {
            call.reject("Failed to get shared container URL")
            return
        }

        let fullPath = sharedContainerURL.appendingPathComponent(path)

        do {
            try FileManager.default.removeItem(at: fullPath)
            call.resolve()
        } catch {
            call.reject(
                "Unable to delete file \(path) from shared container: \(error.localizedDescription)"
            )
        }
    }

    @objc func cleanupOldSharedContainerFiles(_ call: CAPPluginCall) {
        guard let path = call.getString("path") else {
            call.reject("Path parameter is required")
            return
        }

        // Get the shared container URL
        guard
            let sharedContainerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.soundsstudios.wave"
            )
        else {
            call.reject("Failed to get shared container URL")
            return
        }

        let fullPath = sharedContainerURL.appendingPathComponent(path)

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: fullPath,
                includingPropertiesForKeys: [
                    .nameKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey,
                ], options: [])

            // Clean up files older than 24 hours or larger than 500MB
            let maxFileSize: Int64 = 500 * 1024 * 1024  // 500MB
            let maxAge: TimeInterval = 24 * 60 * 60  // 24 hours
            let cutoffDate = Date().addingTimeInterval(-maxAge)

            var deletedCount = 0
            var deletedSize: Int64 = 0

            for url in contents {
                let fileName = url.lastPathComponent

                // Get file attributes
                guard
                    let attributes = try? url.resourceValues(forKeys: [
                        .fileSizeKey, .creationDateKey, .contentModificationDateKey,
                    ])
                else {
                    continue
                }

                let fileSize = Int64(attributes.fileSize ?? 0)
                let creationDate = attributes.creationDate ?? Date.distantPast
                let modificationDate = attributes.contentModificationDate ?? Date.distantPast
                let mostRecentDate = max(creationDate, modificationDate)

                // Delete if file is too large or too old
                if fileSize > maxFileSize || mostRecentDate < cutoffDate {
                    do {
                        try FileManager.default.removeItem(at: url)
                        deletedCount += 1
                        deletedSize += fileSize
                        print("🗑️ Cleaned up file: \(fileName) (\(fileSize) bytes)")
                    } catch {
                        print(
                            "❌ Failed to delete file: \(fileName) - \(error.localizedDescription)")
                    }
                }
            }

            call.resolve([
                "deletedCount": deletedCount,
                "deletedSize": deletedSize,
                "message": "Cleaned up \(deletedCount) files (\(deletedSize) bytes)",
            ])
        } catch {
            call.reject("Failed to cleanup directory: \(error.localizedDescription)")
        }
    }

    @objc func wipeSharedContainerDirectory(_ call: CAPPluginCall) {
        guard let path = call.getString("path") else {
            call.reject("Path parameter is required")
            return
        }

        // Get the shared container URL
        guard
            let sharedContainerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.soundsstudios.wave"
            )
        else {
            call.reject("Failed to get shared container URL")
            return
        }

        let fullPath = sharedContainerURL.appendingPathComponent(path)

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: fullPath,
                includingPropertiesForKeys: [.nameKey, .fileSizeKey],
                options: [])

            var deletedCount = 0
            var deletedSize: Int64 = 0

            // Delete ALL files in the directory
            for url in contents {
                let fileName = url.lastPathComponent

                do {
                    // Get file size before deletion
                    let fileSize = Int64(
                        (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)

                    try FileManager.default.removeItem(at: url)
                    deletedCount += 1
                    deletedSize += fileSize
                    print("🗑️ Wiped file: \(fileName) (\(fileSize) bytes)")
                } catch {
                    print("❌ Failed to delete file: \(fileName) - \(error.localizedDescription)")
                }
            }

            call.resolve([
                "deletedCount": deletedCount,
                "deletedSize": deletedSize,
                "message": "Wiped \(deletedCount) files (\(deletedSize) bytes)",
            ])
        } catch {
            call.reject("Failed to wipe directory: \(error.localizedDescription)")
        }
    }
}
