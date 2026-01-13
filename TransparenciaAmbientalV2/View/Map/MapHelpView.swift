import SwiftUI

struct MapHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Group {
                    Text("Como usar o mapa")
                        .font(.title3).bold()

                    Text("""
                    Esta tela mostra os focos de queimadas no mapa com suporte a:
                    • Agrupamento automático de marcadores (clusters) ao afastar o zoom.
                    • Heatmap para visualizar concentração e intensidade.
                    • Filtros por Estado e Bioma e seleção de data.
                    """)
                    .foregroundColor(.secondary)
                }

                Divider().opacity(0.3)

                Group {
                    Text("Controles")
                        .font(.headline)

                    HelpRow(
                        title: "Data",
                        text: """
                        Toque no pill “Data” para escolher o dia. O máximo permitido é ontem.
                        Ao selecionar um dia, o mapa é atualizado automaticamente.
                        """
                    )

                    HelpRow(
                        title: "Filtros (Estado/Bioma)",
                        text: """
                        Toque nos pills “Estado” e “Bioma” para refinar os focos exibidos.
                        Você pode combinar ambos os filtros. Use “Reset filtros” para limpar.
                        """
                    )

                    HelpRow(
                        title: "Baixar dados",
                        text: """
                        Faz o download dos dados do dia selecionado e atualiza o mapa.
                        O botão fica desabilitado enquanto há uma operação em andamento.
                        """
                    )

                    HelpRow(
                        title: "Limpar dados",
                        text: """
                        Remove todos os dados carregados e retorna o mapa ao estado inicial.
                        O botão fica desabilitado quando já não há dados a limpar.
                        """
                    )
                }

                Divider().opacity(0.3)

                Group {
                    Text("Clusters de marcadores")
                        .font(.headline)

                    HelpRow(
                        title: "Como funciona",
                        text: """
                        Quando há muitos focos próximos, eles são agrupados em um marcador de cluster
                        com um número indicando a quantidade aproximada. Aproximando o zoom, os clusters
                        se dividem em clusters menores ou marcadores individuais.
                        """
                    )
                }

                Divider().opacity(0.3)

                Group {
                    Text("Heatmap e gradiente de cores")
                        .font(.headline)

                    HelpRow(
                        title: "Interpretação",
                        text: """
                        O heatmap destaca áreas com maior densidade/intensidade de focos.
                        As cores seguem um gradiente do frio ao quente:
                        • Verde: baixa concentração/intensidade
                        • Amarelo: média
                        • Vermelho: alta
                        Em algumas regiões muito intensas, pode haver pontos brilhantes no centro.
                        """
                    )

                    HeatmapLegend()
                        .padding(.top, 4)

                    HelpRow(
                        title: "Dica",
                        text: """
                        Use o gesto de pinça para aproximar e revelar detalhes.
                        Combine com filtros por Estado/Bioma para entender padrões locais.
                        """
                    )
                }
            }
            .padding()
        }
    }
}

private struct HeatmapLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legenda do gradiente")
                .font(.subheadline).bold()

            LinearGradient(
                colors: [
                    Color.green.opacity(0.9),
                    Color.yellow.opacity(0.9),
                    Color.orange.opacity(0.95),
                    Color.red
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 14)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
            )

            HStack {
                Text("Baixa").font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text("Alta").font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}
