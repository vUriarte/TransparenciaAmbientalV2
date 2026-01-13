import Foundation

protocol FireDataServiceProtocol {
    func fetchCSV(for date: Date) async throws -> String
}
