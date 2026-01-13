import Foundation

enum LoadState: Equatable {
    case idle
    case loading
    case error(String)
    case success(String)
}
