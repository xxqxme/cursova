import Foundation

@MainActor
class ArtViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var artworks: [Artwork] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // How many objects to fetch details for (keeps UI snappy)
    private let maxResults = 20

    // Search: returns objectIDs array, then fetch details for first N
    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            // clear results if query empty
            artworks = []
            return
        }

        isLoading = true
        errorMessage = nil
        artworks = []

        // Build search URL (filter to items with images)
        guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchURL = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/search?q=\(encoded)&hasImages=true") else {
            errorMessage = "Невірний пошуковий запит"
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: searchURL)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                errorMessage = "HTTP \(http.statusCode)"
                isLoading = false
                return
            }

            // Parse search result: { total: Int, objectIDs: [Int]? }
            struct SearchResult: Codable {
                let total: Int
                let objectIDs: [Int]?
            }
            let result = try JSONDecoder().decode(SearchResult.self, from: data)
            guard let ids = result.objectIDs, !ids.isEmpty else {
                errorMessage = "Нічого не знайдено"
                isLoading = false
                return
            }

            // Limit to first maxResults ids
            let slice = Array(ids.prefix(maxResults))

            // Fetch details concurrently
            var loaded: [Artwork] = []
            try await withThrowingTaskGroup(of: Artwork?.self) { group in
                for id in slice {
                    group.addTask {
                        return try await self.fetchArtworkDetail(id: id)
                    }
                }

                for try await maybeArtwork in group {
                    if let art = maybeArtwork {
                        loaded.append(art)
                    }
                }
            }

            // sort by title (optional) to keep deterministic
            artworks = loaded.sorted { ($0.title ?? "") < ($1.title ?? "") }
            isLoading = false

        } catch {
            errorMessage = "Помилка: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // Fetch single object detail
    private func fetchArtworkDetail(id: Int) async throws -> Artwork? {
        guard let url = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/objects/\(id)") else {
            return nil
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            // ignore this one
            return nil
        }
        let art = try JSONDecoder().decode(Artwork.self, from: data)
        return art
    }
}
