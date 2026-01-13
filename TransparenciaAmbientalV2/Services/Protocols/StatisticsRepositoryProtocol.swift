import Foundation

protocol StatisticsRepositoryProtocol {
    // Retorna focos por data
    func focuses(for dates: [Date]) async throws -> [Date: [FireFocus]]

    // Armazena focos baixados para uma data (para persistência futura)
    func storeFocuses(_ focuses: [FireFocus], for date: Date) async throws

    // Limpa cache/persistência de um conjunto de datas
    func purge(dates: [Date]) async throws
}
