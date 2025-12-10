import Foundation
import SwiftUI

@MainActor
class ArtViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var artworks: [Artwork] = []
    @Published var favorites: [Artwork] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let favoritesKey = "saved_art_v1"

    init() {
        loadFavorites()
    }
    
    func search() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        artworks = []
        
        do {
            let results = try await ArtService.shared.searchArtworks(query: q)
            
            if results.isEmpty {
                errorMessage = "Нічого не знайдено"
            } else {
                artworks = results
            }
        } catch {
            errorMessage = "Помилка завантаження. Перевірте інтернет."
        }
        
        isLoading = false
    }

    func toggleFavorite(_ art: Artwork) {
        if let index = favorites.firstIndex(where: { $0.id == art.id }) {
            favorites.remove(at: index)
        } else {
            favorites.append(art)
        }
        saveFavorites()
    }
    
    func isFavorite(_ art: Artwork) -> Bool {
        return favorites.contains(where: { $0.id == art.id })
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
}
