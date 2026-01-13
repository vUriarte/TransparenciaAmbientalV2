import Foundation

enum StatisticsModuleFactory {
    static func makeViewModel(
        initialStartDate: Date,
        initialEndDate: Date,
        inheritedState: BrazilianState?,
        inheritedBiome: Biome?
    ) async -> StatisticsViewModel {
        let repo = await StatisticsRepositoryCoreData(service: FireDataService(), stack: CoreDataStack())
        let viewModel = StatisticsViewModel(
            repository: repo,
            engine: StatisticsEngine(),
            initialStartDate: initialStartDate,
            initialEndDate: initialEndDate
        )
        // Herda filtros iniciais
        viewModel.selectedState = inheritedState
        viewModel.selectedBiome = inheritedBiome
        return viewModel
    }
}
