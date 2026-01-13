import SwiftUI

struct StatisticsHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Group {
                    Text("Como ler esta tela")
                        .font(.title3).bold()

                    Text("""
                    Esta aba reúne um painel de indicadores e gráficos sobre os focos de queimadas no período selecionado. \
                    Use os filtros no topo para restringir por Estado e Bioma e ajuste o período (7, 15 ou 30 dias). \
                    O conteúdo da tela se atualiza automaticamente conforme suas escolhas.
                    """)
                    .foregroundColor(.secondary)
                }

                Divider().opacity(0.3)

                Group {
                    Text("Indicadores do resumo")
                        .font(.headline)

                    HelpRow(
                        title: "Focos",
                        text: """
                        Quantidade total de focos detectados no recorte atual. \
                        Útil para medir volume absoluto de eventos e acompanhar tendências de curto prazo \
                        (ex.: aumento de focos após um período de estiagem).
                        """
                    )

                    HelpRow(
                        title: "FRP Σ",
                        text: """
                        Soma do Fire Radiative Power (FRP) em megawatts (MW). \
                        O FRP representa a potência radiativa do fogo estimada pelos sensores. \
                        Útil para avaliar a intensidade total dos eventos: dois períodos com a mesma quantidade de focos \
                        podem ter FRP Σ muito diferentes, indicando queimadas mais intensas.
                        """
                    )

                    HelpRow(
                        title: "FRP Média",
                        text: """
                        Média do FRP por foco. \
                        Útil para comparar a intensidade típica dos eventos entre regiões/biomas ou ao longo do tempo. \
                        Sensível a valores extremos (outliers).
                        """
                    )

                    HelpRow(
                        title: "FRP Mediana",
                        text: """
                        Mediana do FRP (50% dos focos têm FRP abaixo deste valor). \
                        Útil quando há muitos outliers de alta intensidade, pois representa melhor o “centro” da distribuição \
                        do que a média.
                        """
                    )

                    HelpRow(
                        title: "FRP P90",
                        text: """
                        Percentil 90 do FRP (apenas 10% dos focos têm FRP acima deste valor). \
                        Útil para monitorar a cauda superior da distribuição e identificar períodos/regiões com eventos \
                        particularmente intensos.
                        """
                    )

                    HelpRow(
                        title: "FRP Máx",
                        text: """
                        Maior FRP observado no período. \
                        Útil para detectar ocorrências extremas e orientar investigações pontuais ou respostas operacionais.
                        """
                    )
                }

                Divider().opacity(0.3)

                Group {
                    Text("Top N por grupo")
                        .font(.headline)

                    HelpRow(
                        title: "Grupos (Estados, Biomas, Municípios)",
                        text: """
                        Lista os grupos com maior relevância conforme a métrica escolhida. \
                        Em Municípios, exibimos “Município (UF)” para facilitar a identificação do estado.
                        """
                    )

                    HelpRow(
                        title: "Métrica: Qtde",
                        text: """
                        Ordena pelo número de focos. \
                        Útil para priorizar onde há maior concentração de ocorrências, \
                        independentemente da intensidade.
                        """
                    )

                    HelpRow(
                        title: "Métrica: FRP (FRP Σ)",
                        text: """
                        Ordena pela soma do FRP. \
                        Útil para identificar os grupos com maior carga térmica total, \
                        destacando onde os eventos tendem a ser mais intensos.
                        """
                    )

                    HelpRow(
                        title: "Participação (%)",
                        text: """
                        Participação de cada grupo no total de focos do recorte. \
                        Útil para contextualizar a importância relativa de um estado/bioma/município \
                        frente ao conjunto analisado.
                        """
                    )
                }

                Divider().opacity(0.3)

                Group {
                    Text("Série temporal")
                        .font(.headline)

                    HelpRow(
                        title: "Qtde (linha)",
                        text: """
                        Mostra a evolução do número de focos ao longo do tempo dentro do período selecionado. \
                        Útil para detectar tendências, sazonalidades e efeitos de curto prazo (ex.: frentes frias, estiagem).
                        """
                    )

                    HelpRow(
                        title: "FRP Σ (área + linha)",
                        text: """
                        Mostra a evolução da intensidade total (soma do FRP) ao longo do tempo. \
                        Útil para identificar períodos de maior severidade, mesmo que a quantidade de focos não varie tanto.
                        """
                    )

                    HelpRow(
                        title: "Eixo X (datas)",
                        text: """
                        Vai do início selecionado até o fim (ontem). \
                        Os rótulos exibem apenas o número do dia para facilitar a leitura rápida.
                        """
                    )
                }

                Divider().opacity(0.3)

                Group {
                    Text("Dicas de análise")
                        .font(.headline)

                    HelpRow(
                        title: "Compare quantidade x intensidade",
                        text: """
                        Use “Qtde” para localizar concentrações de focos e “FRP Σ” para avaliar severidade. \
                        Um grupo pode ter poucos focos mas FRP Σ alto — sinal de eventos intensos.
                        """
                    )

                    HelpRow(
                        title: "Atenção a outliers",
                        text: """
                        Prefira Mediana e P90 quando houver muitos valores extremos. \
                        Eles ajudam a entender o comportamento típico e a cauda superior da distribuição.
                        """
                    )

                    HelpRow(
                        title: "Contexto geográfico",
                        text: """
                        Combine os Top N com os filtros de Estado/Bioma e com o mapa para entender padrões espaciais \
                        e direcionar ações locais.
                        """
                    )

                    HelpRow(
                        title: "Períodos e sazonalidade",
                        text: """
                        Compare janelas (7/15/30 dias) para diferenciar variações de curto prazo de tendências \
                        sazonais. Acompanhe regularmente para identificar mudanças anormais.
                        """
                    )
                }
            }
            .padding()
        }
    }
}
