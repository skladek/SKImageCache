import Foundation

class MockFileManager: FileManager {
    var createDirectoryCalled = false
    var fileExistsCalled = false

    var fileExists = false

    override func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [String : Any]? = nil) throws {
        createDirectoryCalled = true
    }

    override func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        fileExistsCalled = true

        return fileExists
    }
}