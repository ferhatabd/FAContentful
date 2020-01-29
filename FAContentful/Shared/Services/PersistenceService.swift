//
//  PersistenceStore.swift
//  
//
//  Created by Ferhat Abdullahoglu on 27.12.2019.
//

import Foundation
import CoreData
import Contentful
import ContentfulPersistence

final public class PersistenceService {
    
    /* ------------------------------------------------------- */
    // MARK: Properties
    /* ------------------------------------------------------- */
    
    //
    // MARK: Private properties
    //
    
    /// Managed object context
    let managedObjectContext: NSManagedObjectContext
    
    /// Contentful space synchronization handler
    let contentfulSynchronizer: SynchronizationManager
    
    /// CoreData handler
    internal let coreDataStore: CoreDataStore
    
    /// CoreData model URL
    /// will be generated during init
    static internal var storeUrl: URL?
    
    //
    // MARK: Public properties
    //
    public var moc: NSManagedObjectContext {
        managedObjectContext
    }
    
    
    
    /* ------------------------------------------------------- */
    // MARK: Init
    /* ------------------------------------------------------- */
    /// Initializes a **PersistenceService** handler
    /// - Parameters:
    ///   - bundle: Bundle name to look for the model. If no bundle name is given, the current bundle will be used
    ///   - name: Name of the CoreData model. Don't include the *.sqlite* file extension in the parameter
    ///   - spaceType: Synchronized Contentful space
    ///   - assetType: Synchronized Asset type
    ///   - entryTypes: Models to be synchronized
    internal init(bundle: Bundle,
                  dataModelName name: String,
                  spaceType: SyncSpacePersistable.Type,
                  assetType: AssetPersistable.Type,
                  entryTypes: [EntryPersistable.Type],
                  client: Client) {
        
        
        // get the store url
        
        let targetDirectory: FileManager.SearchPathDirectory
        
        if #available(tvOS 13, *) {
            targetDirectory = .cachesDirectory
        } else {
            targetDirectory = .documentDirectory
        }
        
        PersistenceService.storeUrl = FileManager.default.urls(for: targetDirectory, in: .userDomainMask).last?.appendingPathComponent("\(name).sqlite")
        
        // create the persistence model
        let model = PersistenceModel(spaceType: spaceType,
                                     assetType: assetType,
                                     entryTypes: entryTypes)
        
        let managedObjectContext = PersistenceService.setupManagedObjectContext(bundle: bundle, name: name)
        let coreDataStore = CoreDataStore(context: managedObjectContext)
        self.managedObjectContext = managedObjectContext
        self.coreDataStore = coreDataStore
        
        self.contentfulSynchronizer = SynchronizationManager(client: client,
                                                             localizationScheme: .all,
                                                             persistenceStore: coreDataStore,
                                                             persistenceModel: model)
        
    }
    
    
    /* ------------------------------------------------------- */
    // MARK: Methods
    /* ------------------------------------------------------- */
    
    //
    // MARK: Private methods
    //
    /// Creates and returns an **NSManagedObjectContext** for the given model
    /// - Parameters:
    ///   - bundle: Bundle name to look for the model
    ///   - name: Name of the model
    static private func setupManagedObjectContext(bundle: Bundle, name: String) -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let modelUrl = bundle.url(forResource: name, withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelUrl)!
        let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType,
                                       configurationName: nil,
                                       at: PersistenceService.storeUrl!,
                                       options: [NSMigratePersistentStoresAutomaticallyOption : true,
                                                 NSInferMappingModelAutomaticallyOption : true])
        } catch {
            fatalError("can't initialize the persistentStoreCoordinator")
        }
        
        managedObjectContext.persistentStoreCoordinator = psc
        return managedObjectContext
    }
    
    
    //
    // MARK: Public methods
    //
    internal func performSynchronization(completion: @escaping ResultsHandler<SyncSpace>) {
        contentfulSynchronizer.sync { (result) in
            completion(result)
        }
    }
}

