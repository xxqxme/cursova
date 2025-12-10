import Foundation

struct Artwork: Codable, Identifiable, Equatable, Hashable {
    let objectID: Int
    var id: Int { objectID }

    let title: String?
    let artistDisplayName: String?
    let objectDate: String?
    let primaryImageSmall: String?
    let primaryImage: String?
    let medium: String?
    let department: String?

    enum CodingKeys: String, CodingKey {
        case objectID
        case title
        case artistDisplayName
        case objectDate
        case primaryImageSmall
        case primaryImage
        case medium
        case department
    }
}
