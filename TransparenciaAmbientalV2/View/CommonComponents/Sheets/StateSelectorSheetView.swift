import SwiftUI

struct StateSelectorSheetView: View {
    let selected: BrazilianState?
    let onSelect: (BrazilianState?) -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        onSelect(nil)
                    } label: {
                        HStack {
                            Text("Todos")
                            if selected == nil {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                Section("Estados") {
                    ForEach(BrazilianState.allCases, id: \.self) { state in
                        Button {
                            onSelect(state)
                        } label: {
                            HStack {
                                Text(state.displayName)
                                if selected == state {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Selecionar Estado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { onClose() }
                }
            }
        }
    }
}
