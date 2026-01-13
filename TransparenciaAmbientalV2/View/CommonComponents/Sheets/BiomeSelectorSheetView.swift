import SwiftUI

struct BiomeSelectorSheetView: View {
    let selected: Biome?
    let onSelect: (Biome?) -> Void
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
                Section("Biomas") {
                    ForEach(Biome.allCases, id: \.self) { biome in
                        Button {
                            onSelect(biome)
                        } label: {
                            HStack {
                                Text(biome.displayName)
                                if selected == biome {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Selecionar Bioma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { onClose() }
                }
            }
        }
    }
}
