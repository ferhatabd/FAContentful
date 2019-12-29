//
//  ContentfulService.swift
//  
//
//  Created by Ferhat Abdullahoglu on 25.12.2019.
//


import Foundation
import Contentful
import ContentfulPersistence

public typealias ContentCompletion<T> = ([T]?) -> Void

public enum ContentfulErrors: Error {
    case persistenceNotConfigured(String)
}

/// An enumeration to define what editorial state an entry or asset is in.
///
/// - upToDate: The resource is published: the entry has the exact same data when fetched from CDA as when fetched from CPA.
/// - draft: The resource has not yet been published.
/// - pendingChanges: The resource is published, but there are changes available in the CPA that are not yet available on the CDA.
/// - draftAndPendingChanges: A composite state that a `Lesson` or a `HomeLayout` instance may have if any of it's linked modules has `draft` and `pendingChanges` states.
public enum ResourceState {
    case upToDate
    case draft
    case pendingChanges
    case draftAndPendingChanges
}

/// A resource which has it's state.
public protocol StatefulResource: class {
    var state: ResourceState { get set }
}


/// ContentfulService is a type that this app uses to manage state related to Contentful such as which locale
/// should be specified in API requests, and which API should be used: preview or delivery. It also adds some additional
/// methods for "diff'ing" the results from the preview and delivery APIs so that the states of resources can be inferred.
final public class ContentfulService {
    
    /* ------------------------------------------------------- */
    // MARK: Properties
    /* ------------------------------------------------------- */
    
    //
    // MARK: Private properties
    //
    
    /// The locale code of the currently selected locale.
    private var currentLocaleCode: LocaleCode {
        return stateMachine.state.locale.code
    }
    
    
    /// Contentful session
    private let session: Session
    
    /// Credentials structure
    private let credentials: ContentfulCredentials
    
    /// Dispatch queue for handling the tasks related to Contenful
    private let contentQueue = DispatchQueue(label: "com.ferhatab.contentfulapi",
                                             qos: .userInitiated)
    
    
    
    //
    // MARK: Internal properties
    //
    /// An array of all the content types that will be used by the apps instance of `ContentfulService`.
    internal var contentTypeClasses: [EntryDecodable.Type] = [ ] {
        didSet {
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }
                self.setupClients()
            }
        }
    }
    
    //
    // MARK: Public properties
    //
    
    /// A struct that represents the state of the Contentful service at any given time.
    /// One nice property of this type is that since it's a struct, a change to any member variable
    /// is a change to the entity itself. We can use this type in conjunction with a the `StateMachine` type
    /// to observe state changes in all the UI of the application.
    public struct State {
        
        public var currentLocale: Contentful.Locale {
            locale
        }
        
        /// The currently selected API that the app is pulling data from.
        var api: API
        
        /// The currently selected locale that the app is using to localize content.
        var locale: Contentful.Locale
        
        /// If pulling data from the CPA and this switch is on, resource state pills will be shown in the user interface.
        var editorialFeaturesEnabled: Bool
        
        /// An enumeration of all the possible API's this ContentfulService can interface with.
        ///
        /// - delivery: A enum representation of the Content Delivery API.
        /// - preview: A enum representation of the Content Preview API.
        public enum API: String {
            case delivery
            case preview
            
            func title() -> String {
                switch self {
                case .delivery:
                    return "API: Delivery"
                case .preview:
                    return "API: Preview"
                }
            }
        }
    }
    
    /// The state machine that the app will use to observe state changes and execute relevant updates.
    public let stateMachine: StateMachine<ContentfulService.State>
    
    /// The client used to pull data from the Content Delivery API.
    public var deliveryClient: Client
    
    /// The client used to pull data from the Content Preview API.
    public var previewClient: Client
    
    
    /// A computed variable describing if views for Contentful resources should render state labels.
    public var shouldShowResourceStateLabels: Bool {
        return editorialFeaturesAreEnabled && stateMachine.state.api == .preview
    }
    
    /// Returns true if editorial features are enabled.
    public var editorialFeaturesAreEnabled: Bool {
        return stateMachine.state.editorialFeaturesEnabled
    }
    
    /// The available locales for the connected Contentful space. If there is an issue connecting to
    /// Contentful, a default array will be returned containing en-US and de-DE.
    public var locales: [Contentful.Locale] {
        let semaphore = DispatchSemaphore(value: 0)
        
        var locales = [Contentful.Locale]()
        
        client.fetchLocales { result in
            if let response = result.value {
                locales = response.items
            } else {
                locales = [.americanEnglish(), .german(), .turkish()]
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return locales
    }
    
    
    /// Depending on the state of the ContentfulService, this Client will either be connected to the Delivery API, or the Preview API.
    public var client: Client {
        switch stateMachine.state.api {
        case .delivery: return deliveryClient
        case .preview: return previewClient
        }
    }
    
    /// Returns the current state of the service
    public var state: State {
        stateMachine.state
    }
    
    /// Persistence handler -- will be made available upon demand
    public var persistentStore: PersistenceService?
    
    /* ------------------------------------------------------- */
    // MARK: Init
    /* ------------------------------------------------------- */
    
    public init(session: Session, credentials: ContentfulCredentials, state: State) {
        self.session = session
        self.credentials = credentials
        
        self.deliveryClient = Client(spaceId: credentials.spaceId,
                                     accessToken: credentials.deliveryAPIAccessToken,
                                     host: "cdn." + credentials.domainHost,
                                     contentTypeClasses: contentTypeClasses)
        
        // This time, we configure the client to pull content from the Content Preview API.
        self.previewClient = Client(spaceId: credentials.spaceId,
                                    accessToken: credentials.previewAPIAccessToken,
                                    host: "preview." + credentials.domainHost,
                                    contentTypeClasses: contentTypeClasses)
        
        self.stateMachine = StateMachine<State>(initialState: state)
    }
    
    
    /* ------------------------------------------------------- */
    // MARK: Methods
    /* ------------------------------------------------------- */
    
    //
    // MARK: Private methods
    //
    /// Sets up the clients on demand
    private func setupClients() {
        self.deliveryClient = Client(spaceId: credentials.spaceId,
                                     accessToken: credentials.deliveryAPIAccessToken,
                                     host: "cdn." + credentials.domainHost,
                                     contentTypeClasses: contentTypeClasses)
        
        // This time, we configure the client to pull content from the Content Preview API.
        self.previewClient = Client(spaceId: credentials.spaceId,
                                    accessToken: credentials.previewAPIAccessToken,
                                    host: "preview." + credentials.domainHost,
                                    contentTypeClasses: contentTypeClasses)
    }
    
    /// This method will take a resource that was fetched from The Preview API, and the Wrapping result type returned after fetching
    /// the same resource from the Delivery API and compare the updatedAt dates together to see if the preview resource is "Draft", "Pending changes",
    /// or completely up-to-date.
    ///
    /// - Parameters:
    ///   - previewResource: The Preview API resource for which a state determination will be made.
    ///   - deliveryResult: The result of the Delivery API GET request which fetched the same resource, but with Delivery API values.
    /// - Returns: Returns the preview resource originally passed in, but with it's state property updated.
    private func inferStateFromDiffs<T>(previewResource: T, deliveryResource: T?) -> T where T: StatefulResource & Resource {
        
        if let deliveryResource = deliveryResource {
            if deliveryResource.sys.updatedAt!.isEqualTo(previewResource.sys.updatedAt!) == false {
                previewResource.state = .pendingChanges
            }
        } else {
            // The Resource is available on the Preview API but not the Delivery API, which means it's in draft.
            previewResource.state = .draft
        }
        return previewResource
    }
    
    //
    // MARK: Public methods
    //
    
    
    /// A method to change the state of the receiving service to enable/disable editorial features.
    ///
    /// - Parameter shouldEnable: A boolean describing if editorial features should be enabled. `true` will enable editorial features.
    public func enableEditorialFeatures(_ shouldEnable: Bool) {
        session.persistEditorialFeatureState(isOn: shouldEnable)
        stateMachine.state.editorialFeaturesEnabled = shouldEnable
    }
    
    public func setLocale(_ locale: Contentful.Locale) {
        session.persistLocale(locale)
        stateMachine.state.locale = locale
    }
    
    public func setAPI(_ api: ContentfulService.State.API) {
        session.persistAPI(api)
        stateMachine.state.api = api
    }
    
    /// If the receiving ContentfulService is in a state in which resource states should be resolved and
    /// rendered in the relevant views, this method will return `true` and trigger the logic to resolve said resource states.
    ///
    /// - Parameters:
    ///   - resource: The resource for which the state determination is being made.
    ///   - completion: A completion handler returning a stateful preview API resource.
    /// - Returns: A boolean value indicating if the state resolution logic will be executed.
    @discardableResult public func willResolveStateIfNecessary<T>(for resource: T,
                                                                  then completion: @escaping (Result<T>, T?) -> Void) -> Bool
        where T: FieldKeysQueryable & EntryDecodable & Resource & StatefulResource {
            
            switch stateMachine.state.api {
                
            case .preview where stateMachine.state.editorialFeaturesEnabled == true:
                let query = QueryOn<T>.where(sys: .id, .equals(resource.id))
                
                deliveryClient.fetchArray(of: T.self, matching: query) { [unowned self] deliveryResult in
                    if let error = deliveryResult.error {
                        completion(Result.error(error), nil)
                    }
                    
                    let statefulPreviewResource = self.inferStateFromDiffs(previewResource: resource,
                                                                           deliveryResource: deliveryResult.value?.items.first)
                    completion(Result.success(statefulPreviewResource), deliveryResult.value?.items.first)
                }
                return true
            default:
                // If not connected to the Preview API with editorial features enabled, continue execution without
                // additional state resolution.
                return false
            }
    }
    
    /// This method takes a parent entry that links to an array of linked `Module`s and will calculate
    /// the states of all those modules by comparing their values on the Preview and Delivery APIs. This method will update the state
    /// of the passed in Preview API parent entry and update it's state property if any of it's linked modules are in "Pending Changes" or in "Draft" states.
    ///
    /// - Parameters:
    ///   - statefulRootAndModules: A tuple of a parent entry and it's linked modules array. The parent and modules
    ///   should both have been fetched from the Preview API.
    ///   - deliveryModules: The same module entities in their most recently published state: i.e. fetched from the Delivery API.
    /// - Returns: A reference to the parent entry with it's state now modified to reflect the collective states of its linked modules.
    public func inferStateFromLinkedModuleDiffs<T>(statefulRootAndModules: (T, [Module]),
                                                   deliveryModules: [Module]) -> T where T: StatefulResource {
        
        var (previewRoot, previewModules) = statefulRootAndModules
        let deliveryModules = deliveryModules
        
        // Check for newly linked/unlinked modules.
        if deliveryModules.count != previewModules.count {
            previewRoot.state = .pendingChanges
        }
        // Check if modules have been reordered
        for index in 0..<deliveryModules.count {
            if previewModules[index].sys.id != deliveryModules[index].sys.id {
                previewRoot.state = .pendingChanges
            }
        }
        
        // Now resolve state for each preview module.
        for i in 0..<previewModules.count {
            let deliveryModule = deliveryModules.filter({ $0.sys.id == previewModules[i].sys.id }).first
            previewModules[i] = inferStateFromDiffs(previewResource: previewModules[i], deliveryResource: deliveryModule)
        }
        
        let previewModuleStates = previewModules.map { $0.state }
        let numberOfDraftModules =  previewModuleStates.filter({ $0 == .draft }).count
        let numberOfPendingChangesModules =  previewModuleStates.filter({ $0 == .pendingChanges }).count
        
        // Calculate the state of the root parent entry based on it's linked modules.
        if numberOfDraftModules > 0 && numberOfPendingChangesModules > 0 {
            previewRoot.state = .draftAndPendingChanges
        } else if numberOfDraftModules > 0 && numberOfPendingChangesModules == 0 {
            if previewRoot.state == .pendingChanges {
                previewRoot.state = .draftAndPendingChanges
            } else {
                previewRoot.state = .draft
            }
        } else if numberOfDraftModules == 0 && numberOfPendingChangesModules > 0 {
            if previewRoot.state == .draft {
                previewRoot.state = .draftAndPendingChanges
            } else {
                previewRoot.state = .pendingChanges
            }
        }
        
        return previewRoot
    }
    
    
    /// If connected to the original space which is maintained by Contentful and has read-only access this will return `true`.
    public var isConnectedToDefaultSpace: Bool {
        credentials.spaceId == ContentfulCredentials.default.spaceId
            && credentials.deliveryAPIAccessToken == ContentfulCredentials.default.deliveryAPIAccessToken
            && credentials.previewAPIAccessToken == ContentfulCredentials.default.previewAPIAccessToken
    }
    
    
    /// Sets the content types
    /// - Parameter contents: Types to be used
    public func setContentType(_ contents: [EntryDecodable.Type]) {
        self.contentTypeClasses = contents
    }
    
    /// Executes a fetch request on the given type
    ///
    ///  - Important:
    ///   If a type that's not set with the **setContentType(_:)**  is queried upon, the results array won't have
    ///   the requested values because the server doesn't know then how to parse the related JSON data
    ///   to the related object
    ///
    /// - Parameters:
    ///   - type: Generic type who must be set before via **setContentType(_:)** method
    ///   - completion: Callback with the results
    public func getEntry<Content>(_ type: Content.Type, completion: @escaping ContentCompletion<Content>) where Content: FAContent {
        let query = QueryOn<Content>()
        contentQueue.async { [weak self] in
            guard let self = self else { return }
            self.client.fetchArray(of: Content.self, matching: query) { (results) in
                completion(results.value?.items)
            }
        }
    }
    
    public func firstSupportedFallbackLocale(start locale: Contentful.Locale) -> Contentful.Locale? {
        guard let fallbackLocaleCode = locale.fallbackLocaleCode else { return nil }
        guard let fallbackLocale = self.locales.filter({ $0.code == fallbackLocaleCode }).first else { return nil }
        
        // Check if the locale has a localization file in the app's buncle.
        if Bundle.main.path(forResource: fallbackLocale.code, ofType: "lproj") == nil {
            // Recurse.
            return firstSupportedFallbackLocale(start: fallbackLocale)
        }
        return fallbackLocale
    }
    
    /// Initializes and starts a persistent store from the given
    /// model
    /// - Parameters:
    ///   - name: Name of the CoreData model - *.sqlite* extension must be skipped
    ///   - bundle: Bundle to look for the CoreData model. If it's skipped, the current package bundle will be used
    ///   - spaceType: Type of the Contentful Space
    ///   - assetType: Type of th Asset to be maintained
    ///   - entryTypes: Types to be managed
    ///
    /// - Returns: Created PersistenStore - can be ignored
    @discardableResult
    public func initPersistance(dataModelName name: String,
                                inBundle bundle: Bundle? = nil,
                                spaceType: SyncSpacePersistable.Type,
                                assetType: AssetPersistable.Type,
                                entryTypes: [EntryPersistable.Type]) -> PersistenceService {
        
        let _bundle = bundle ?? Bundle(for: ContentfulService.self)
        let ps = PersistenceService(bundle: _bundle,
                                    dataModelName: name,
                                    spaceType: spaceType,
                                    assetType: assetType,
                                    entryTypes: entryTypes,
                                    client: self.client)
        self.persistentStore = ps
        
        return ps
    }
    
    public func sync(completion: @escaping ResultsHandler<SyncSpace>) throws {
        guard let ps = self.persistentStore else {
            throw ContentfulErrors.persistenceNotConfigured("Persistent store requested before it's configured, please run initPersistence() method first")
        }
        
        contentQueue.async {
            ps.performSynchronization(completion: completion)
        }
    }
    
    /// Returns the asked objects from the local storage
    ///  - Note:
    ///  The function can be genericly used for any locally stored object. Therefore to be able to correctly
    ///  infer the datatype, it's important to strictly write the type of the output variable.
    ///  For example:
    ///  Insetad of
    ///  ` let courses = service.fetchAll()  `
    ///  write
    ///  `let courses: [Course] = service.fetchAll()`
    /// - Parameter predicate: Predicate to be used
    /// - throws
    /// Method can throw **ContentfulErrors** or the subsequent errors from **CoreData** depending on the operation
    public func fetchAll<T: EntryPersistable>(where predicate: String?=nil) throws -> [T] {
        guard let ps = self.persistentStore else {
            throw ContentfulErrors.persistenceNotConfigured("Persistent store requested before it's configured, please run initPersistence() method first")
        }
        let fetchPredicate = predicate != nil ? NSPredicate(format: predicate!) : NSPredicate(value: true)
        do {
            let results: [T] = try ps.coreDataStore.fetchAll(type: T.self, predicate: fetchPredicate)
            return results
        } catch {
            throw error
        }
    }
    
    
    public func save() throws {
        guard let ps = persistentStore else {
            throw ContentfulErrors.persistenceNotConfigured("")
        }
        
        do {
            try ps.coreDataStore.save()
        } catch {
            throw error
        }
    }
}



