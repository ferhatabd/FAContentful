//
//  File.swift
//  
//
//  Created by Ferhat Abdullahoglu on 25.12.2019.
//

import Foundation
import Contentful

extension TimeInterval {
    static let twoDays: TimeInterval = 172800
}

/// A class which manages information about the active session of the application.
/// It handles persisting and expiring session information to the application's specifications created by Contentful.
final public class Session {
    
    static let userDefaultsCredentialsKey = "credentials"
    static let lastTimeCredentialsPersistedKey = "lastTimeCredentialsPersisted"
    static let lastTimeEditorialFeaturesPersistedKey = "lastTimeEditorialFeaturesPersisted"
    static let lastTimeLocalePersistedKey = "lastTimeLocalePersistedPersisted"
    static let lastTimeAPIPersistedKey = "lastTimeAPIPersisted"
    
    static let editorialFeaturesEnabledKey = "editorialFeaturesEnabled"
    static let contentfulLocaleKey = "contentfulLocale"
    static let contentfulAPIKey = "contentfulAPI"
    
    static let twoDays: TimeInterval = 172800
    
    var spaceCredentials: ContentfulCredentials
    
    let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = .standard, sessionExpirationWindow: TimeInterval?=nil) {
        self.userDefaults = userDefaults
        
        let _sessionExpirationWindow = sessionExpirationWindow ?? Session.twoDays
        
        if let data = userDefaults.data(forKey: Session.userDefaultsCredentialsKey),
            let credentials = try? JSONDecoder().decode(ContentfulCredentials.self, from: data),
            let lastPersistDate = userDefaults.object(forKey: Session.lastTimeCredentialsPersistedKey) as? Date,
            Date().timeIntervalSince(lastPersistDate) <= _sessionExpirationWindow {
            spaceCredentials = credentials
        } else {
            spaceCredentials = .default
        }
        
        // Reset the editorial features if the we've passsed the expiration date.
        if let lastPersistDate = userDefaults.object(forKey: Session.lastTimeEditorialFeaturesPersistedKey) as? Date,
            Date().timeIntervalSince(lastPersistDate) > _sessionExpirationWindow {
            persistEditorialFeatureState(isOn: false)
        }
        
        if let lastPersistDate = userDefaults.object(forKey: Session.lastTimeLocalePersistedKey) as? Date,
            Date().timeIntervalSince(lastPersistDate) > _sessionExpirationWindow {
            persistLocale(Contentful.Locale.americanEnglish())
        }
        
        if let lastPersistDate = userDefaults.object(forKey: Session.lastTimeAPIPersistedKey) as? Date,
            Date().timeIntervalSince(lastPersistDate) > _sessionExpirationWindow {
            persistAPI(ContentfulService.State.API.delivery)
        }
    }
    
    internal func persistLocale(_ locale: Contentful.Locale) {
        userDefaults.set(locale.code, forKey: Session.contentfulLocaleKey)
        userDefaults.set(Date(), forKey: Session.lastTimeLocalePersistedKey)
    }
    
    internal func persistedLocaleCode() -> String? {
        return userDefaults.string(forKey: Session.contentfulLocaleKey)
    }
    
    internal func persistedAPIRawValue() -> String? {
        return userDefaults.string(forKey: Session.contentfulAPIKey)
    }
    
    internal func persistAPI(_ api: ContentfulService.State.API) {
        userDefaults.set(api.rawValue, forKey: Session.contentfulAPIKey)
        userDefaults.set(Date(), forKey: Session.lastTimeAPIPersistedKey)
    }
    
    internal func persistEditorialFeatureState(isOn: Bool) {
        userDefaults.set(isOn, forKey: Session.editorialFeaturesEnabledKey)
        // Update persistence window.
        userDefaults.set(Date(), forKey: Session.lastTimeEditorialFeaturesPersistedKey)
    }
    
    func areEditorialFeaturesEnabled() -> Bool {
        return userDefaults.bool(forKey: Session.editorialFeaturesEnabledKey)
    }
    
    internal func persistCredentials() {
        if let data = try? JSONEncoder().encode(self.spaceCredentials) {
            userDefaults.set(data, forKey: Session.userDefaultsCredentialsKey)
            // Update persistence window.
            userDefaults.set(Date(), forKey: Session.lastTimeCredentialsPersistedKey)
        }
    }
}



