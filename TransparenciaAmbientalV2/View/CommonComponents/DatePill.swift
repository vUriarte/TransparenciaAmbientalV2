import SwiftUI

struct DatePill: View {
    @Binding var date: Date
    @State private var showingPicker = false
    
    private var maxSelectableDate: Date {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        return cal.date(byAdding: .day, value: -1, to: todayStart) ?? Date()
    }
    
    private var formatted: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.setLocalizedDateFormatFromTemplate("dd MMM yyyy")
        return df.string(from: date)
    }
    
    var body: some View {
        Button {
            // Se a data atual estiver acima do máximo, corrige antes de abrir
            if date > maxSelectableDate {
                date = maxSelectableDate
            }
            showingPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .imageScale(.medium)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .center, spacing: 2) {
                    Text("Data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatted)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 36)
            .frame(maxWidth: .infinity, alignment: .center) 
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            NavigationView {
                VStack {
                    DatePicker(
                        "Selecionar data",
                        selection: $date,
                        in: ...maxSelectableDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    Spacer()
                }
                .navigationTitle("Selecionar data")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showingPicker = false }
                    }
                }
                .onAppear {
                    if date > maxSelectableDate {
                        date = maxSelectableDate
                    }
                }
            }
        }
        // Fecha automaticamente a sheet assim que o usuário toca em um dia
        .onChange(of: date) { _, _ in
            if showingPicker {
                DispatchQueue.main.async { showingPicker = false }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Data")
        .accessibilityValue(formatted)
    }
}
