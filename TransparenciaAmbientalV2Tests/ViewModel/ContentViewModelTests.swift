import Testing
import MapKit
@testable import TransparenciaAmbientalV2

// Mock do serviço para injeção
actor MockFireDataService: FireDataServiceProtocol {
    enum Mode {
        case success(String)
        case failure(Error)
    }
    var mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func fetchCSV(for date: Date) async throws -> String {
        switch mode {
        case .success(let csv):
            return csv
        case .failure(let err):
            throw err
        }
    }
}

@Suite("ContentViewModel download flow")
struct ContentViewModelTests {

    @Test("Fluxo de sucesso popula pontos e estado success")
    @MainActor
    func successFlow() async throws {
        let csv = """
        id,lat,lon,municipio
        a, -10.0, -50.0,TESTE
        b,  -9.5, -49.5,TESTE2
        """
        let mock = MockFireDataService(mode: .success(csv))
        let vm = ContentViewModel(service: mock)

        await vm.downloadData()

        #expect(vm.focuses.count == 2)
        if case .success(let msg) = vm.state {
            #expect(msg.contains("2"))
        } else {
            Issue.record("Estado esperado .success, obtido \(String(describing: vm.state))")
        }
    }

    @Test("Erro do serviço resulta em estado .error")
    @MainActor
    func errorFlow() async throws {
        struct DummyError: Error {}
        let mock = MockFireDataService(mode: .failure(DummyError()))
        let vm = ContentViewModel(service: mock)

        await vm.downloadData()

        if case .error = vm.state {
            #expect(true)
        } else {
            Issue.record("Estado esperado .error, obtido \(String(describing: vm.state))")
        }
    }

    @Test("Detecta chaves lat/lon corretamente (via mapper)")
    func detectLatLonKeys() throws {
        let headers = ["id","lat","lon","data_hora_gmt"]
        let (latKey, lonKey) = FireFocusRowMapper.detectLatLonKeys(headers: headers)
        #expect(latKey == "lat")
        #expect(lonKey == "lon")
    }
}
