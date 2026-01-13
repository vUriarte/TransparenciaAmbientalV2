# 🔥 Transparência Ambiental V2

> Monitoramento de focos de incêndio no Brasil em tempo real

Um aplicativo iOS que democratiza o acesso aos dados oficiais de queimadas do INPE, oferecendo visualizações interativas e análises estatísticas para pesquisadores, ambientalistas e cidadãos.

## 📱 Screenshots

| Mapa Interativo | Estatísticas | Heatmap |
|---|---|---|
| *Visualização dos focos* | *Análises detalhadas* | *Densidade de queimadas* |

## ✨ Funcionalidades

- 🗺️ **Mapa Interativo**: Visualização georreferenciada dos focos de incêndio
- 📊 **Estatísticas Avançadas**: Gráficos e métricas detalhadas
- 🔥 **Heatmaps**: Densidade visual de queimadas
- 🌎 **Filtros Geográficos**: Por estado e bioma brasileiro
- 📅 **Análise Temporal**: Tendências ao longo do tempo
- 💾 **Cache Inteligente**: Dados offline para melhor performance
- 📈 **Métricas FRP**: Fire Radiative Power e estatísticas avançadas

## 🛠️ Tecnologias

- **SwiftUI** - Interface moderna e declarativa
- **MapKit** - Visualização de mapas nativos
- **Core Data** - Persistência local otimizada
- **Swift Charts** - Gráficos interativos (iOS 16+)
- **MVVM** - Arquitetura escalável

## 📋 Requisitos

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## 🚀 Instalação

1. Clone o repositório:
```bash
git clone https://github.com/victoruriarte/TransparenciaAmbientalV2.git
cd TransparenciaAmbientalV2
```

2. Abra o projeto no Xcode:
```bash
open TransparenciaAmbientalV2.xcodeproj
```

3. Execute o projeto (⌘+R)

## 📊 Fonte de Dados

Os dados são obtidos diretamente do **INPE** (Instituto Nacional de Pesquisas Espaciais):
- **URL**: `https://dataserver-coids.inpe.br/queimadas/`
- **Formato**: CSV diário
- **Atualização**: Dados atualizados diariamente
- **Cobertura**: Todo território brasileiro

## 🏗️ Arquitetura

```
├── Model/              # Modelos de dados (FireFocus, BrazilianState, Biome)
├── View/               # Interface SwiftUI
│   ├── Map/           # Componentes do mapa
│   ├── Statistics/    # Telas de análise
│   └── Components/    # Componentes reutilizáveis
├── ViewModel/          # Lógica de apresentação (MVVM)
├── Services/           # Camada de dados e networking
├── Helpers/            # Utilitários e extensões
└── CoreDataAdditions/  # Persistência e cache
```

## 🧪 Testes

Execute os testes no Xcode:
```bash
⌘+U  # Executar todos os testes
```

**Cobertura de testes:**
- ✅ Unit Tests (Models, Services, ViewModels)
- ✅ Integration Tests (API, Core Data)
- ✅ UI Tests (Fluxos principais)


## 📞 Contato

**Victor Uriarte**
- GitHub: [@victoruriarte](https://github.com/victoruriarte)
- Email: [uriarte0505@gmail.com](mailto:uriarte0505@gmail.com)

---