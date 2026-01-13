import SwiftUI

struct StatusOverlay: View {
    @Binding var state: LoadState
    var loadingText: String = "Carregando dados..."
    var autoHideSuccessAfter: Duration = .seconds(3)

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView(loadingText)
                    .padding()
                    .background(.bar)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    .padding()
                    .transition(.opacity.combined(with: .scale))

            case .error(let message):
                Text(message)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    .padding()
                    .onTapGesture {
                        withAnimation {
                            state = .idle
                        }
                    }
                    .transition(.opacity)

            case .success(let message):
                Text(message)
                    .font(.caption)
                    .padding(8)
                    .background(.bar, in: RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    .padding()
                    .transition(.opacity.animation(.easeInOut))
                    .task(id: stateID) {
                        // Auto-oculta após o período configurado
                        try? await Task.sleep(for: autoHideSuccessAfter)
                        if case .success = state {
                            withAnimation {
                                state = .idle
                            }
                        }
                    }

            case .idle:
                EmptyView()
            }
        }
    }

    private var stateID: String {
        if case .success(let message) = state {
            return "success-\(message)"
        } else {
            return "other"
        }
    }
}
