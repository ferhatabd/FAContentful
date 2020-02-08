//
//  Server.swift
//
// Contentful service server
//
//  Created by Ferhat Abdullahoglu on 25.12.2019.
//

import Foundation
import Contentful

/// A class that acts as a service bus, bussing around services down through the various components of the app.
final public class ContentfulServer {
    
    public var session: Session
    
    public var contentful: ContentfulService {
        didSet {
            contentfulStateMachine.state = contentful
        }
    }
    
    
    /// Available locales by default
    /// override the property to supply additional Locales
    public var availableLocales: [Contentful.Locale] {
        [Contentful.Locale.americanEnglish(), Contentful.Locale.german(), Contentful.Locale.turkish()]
    }
    
    public let contentfulStateMachine: StateMachine<ContentfulService>
    
    public func resetCredentialsAndResetLocaleIfNecessary() {
        guard let defaultCredentials = ContentfulCredentials.default else { preconditionFailure("configure Contentful credentials earlier") }
        
        // Retain state from last ContentfulService, but ensure we are using a locale that is available in default space.
        var state = contentful.stateMachine.state
        state.locale = availableLocales.contains(contentful.stateMachine.state.locale) ? contentful.stateMachine.state.locale : Contentful.Locale.americanEnglish()
        contentful = ContentfulService(session: session,
                                       credentials: defaultCredentials,
                                       state: state)
        
        session.spaceCredentials = defaultCredentials
        session.persistCredentials()
    }
    
    public init(session: Session) {
        self.session = session
        let spaceCredentials = session.spaceCredentials
        
        let api = ContentfulService.State.API(rawValue: session.persistedAPIRawValue() ?? ContentfulService.State.API.delivery.rawValue)!
        let state = ContentfulService.State(api: api,
                                            locale: .americanEnglish(),
                                            editorialFeaturesEnabled: session.areEditorialFeaturesEnabled())
        contentful = ContentfulService(session: session,
                                       credentials: spaceCredentials,
                                       state: state)
        if let persistedLocaleCode = session.persistedLocaleCode(),
            let index = contentful.locales.map({ $0.code }).firstIndex(of: persistedLocaleCode) {
            contentful.setLocale(contentful.locales[index])
        } else {
            contentful.setLocale(.americanEnglish())
        }
        contentfulStateMachine = StateMachine(initialState: contentful)
    }
}
