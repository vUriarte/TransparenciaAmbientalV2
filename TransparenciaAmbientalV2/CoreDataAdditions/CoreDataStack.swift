import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TransparenciaAmbiental")
        if inMemory {
            let d = NSPersistentStoreDescription()
            d.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [d]
        } else {
            container.persistentStoreDescriptions.forEach { desc in
                desc.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
                desc.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            }
        }
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("CoreData load error: \(error)") }
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }
}