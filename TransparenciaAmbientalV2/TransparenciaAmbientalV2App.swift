import SwiftUI

@main
struct TransparenciaAmbientalV2App: App {
    let coreData = CoreDataStack.shared
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, coreData.viewContext)
        }
    }
}

