import Foundation
import SwiftUI

@MainActor
class ArtViewModel: ObservableObject {
    // --- Пошук ---
    @Published var query: String = ""
    @Published var artworks: [Artwork] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // --- Улюблене ("Моя Колекція") ---
    @Published var favorites: [Artwork] = []
    private let favoritesKey = "saved_artworks"

    init() {
        loadFavorites() // Завантажуємо збережені при старті
    }

    // Збереження списку улюблених у пам'ять телефону
    func toggleFavorite(_ art: Artwork) {
        if favorites.contains(art) {
            favorites.removeAll { $0.id == art.id }
        } else {
            favorites.append(art)
        }
        saveFavorites()
    }
    
    func isFavorite(_ art: Artwork) -> Bool {
        return favorites.contains(art)
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([Artwork].self, from: data) {
            favorites = decoded
        }
    }

    // --- Логіка Пошуку (твоя стара логіка) ---
    private let maxResults = 20

    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            artworks = []
            return
        }

        isLoading = true
        errorMessage = nil
        artworks = []

        guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let searchURL = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/search?q=\(encoded)&hasImages=true") else {
            errorMessage = "Невірний запит"
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: searchURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                errorMessage = "Помилка сервера"
                isLoading = false
                return
            }

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

            let slice = Array(ids.prefix(maxResults))
            var loaded: [Artwork] = []
            
            // Паралельне завантаження деталей
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

            artworks = loaded.sorted { ($0.title ?? "") < ($1.title ?? "") }
            isLoading = false

        } catch {
            errorMessage = "Помилка: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func fetchArtworkDetail(id: Int) async throws -> Artwork? {
        guard let url = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/objects/\(id)") else { return nil }
        let (data, response) = try await URLSession.shared.data(from: url)
        if (response as? HTTPURLResponse)?.statusCode != 200 { return nil }
        return try? JSONDecoder().decode(Artwork.self, from: data)
    }
}
