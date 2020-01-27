
import Foundation
import Contentful

/// A small wrapper around the credentials for a space.
public struct ContentfulCredentials: Codable, Equatable {

    public static func ==(lhs: ContentfulCredentials, rhs: ContentfulCredentials) -> Bool {
        return lhs.spaceId == rhs.spaceId && lhs.deliveryAPIAccessToken == rhs.deliveryAPIAccessToken && lhs.previewAPIAccessToken == rhs.previewAPIAccessToken
    }

    static let defaultDomainHost = "contentful.com"

    let spaceId: String
    let deliveryAPIAccessToken: String
    let previewAPIAccessToken: String
    let domainHost: String

    /**
     * Pulls the default space credentials from the Example App Space owned by Contentful.
     */
    public static var `default`: ContentfulCredentials!
    
    public static var isSet = false
    
    public static func defaults(spaceId: String, deliveryAccessToken: String, previewAccessToken: String) {
        let credentials = ContentfulCredentials(spaceId: spaceId,
                                                deliveryAPIAccessToken: deliveryAccessToken,
                                                previewAPIAccessToken: previewAccessToken,
                                                domainHost: ContentfulCredentials.defaultDomainHost)
        ContentfulCredentials.default = credentials
        ContentfulCredentials.isSet = true
    }
    
}
