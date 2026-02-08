import Foundation

struct FirmwareCache {
    private let cacheDirectory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = docs.appendingPathComponent("firmware", isDirectory: true)
    }

    func ensureDirectory() throws {
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    func cacheFirmware(version: String, data: Data) throws {
        try ensureDirectory()
        let fileURL = cacheDirectory.appendingPathComponent("\(version).bin")
        try data.write(to: fileURL)
    }

    func getCachedFirmware(version: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent("\(version).bin")
        return FileManager.default.contents(atPath: fileURL.path)
    }

    func isCached(version: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(version).bin")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    func getCachedVersions() -> [String] {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: cacheDirectory.path) else {
            return []
        }
        return files
            .filter { $0.hasSuffix(".bin") }
            .map { String($0.dropLast(4)) }
    }

    func deleteCachedFirmware(version: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(version).bin")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    func clearAll() throws {
        if FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try FileManager.default.removeItem(at: cacheDirectory)
        }
    }
}
