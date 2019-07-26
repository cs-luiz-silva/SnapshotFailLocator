import Foundation

public protocol FileManagerType {
    func removeItem(at url: URL) throws
}

extension FileManager: FileManagerType {

}
