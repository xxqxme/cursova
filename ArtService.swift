//
//  ArtService.swift
//  ArtApp
//
//  Created by ІПЗ-31/2 on 09.12.2025.
//

import Foundation

class ArtService {
    
    static let shared = ArtService()
    
    private let baseURL = "https://collectionapi.metmuseum.org/public/collection/v1"
    
    private init() {}
    
    func searchArtworks(query: String, limit: Int = 20) async throws -> [Artwork] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encoded)&hasImages=true") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct SearchResult: Decodable {
            let objectIDs: [Int]?
        }
        
        let result = try JSONDecoder().decode(SearchResult.self, from: data)
        guard let ids = result.objectIDs, !ids.isEmpty else { return [] }
        
        let idsToLoad = Array(ids.prefix(limit))
        var loadedArtworks: [Artwork] = []
        
        try await withThrowingTaskGroup(of: Artwork?.self) { group in
            for id in idsToLoad {
                group.addTask { await self.fetchDetail(id: id) }
            }
            
            for try await art in group {
                if let art = art {
                    loadedArtworks.append(art)
                }
            }
        }
        
        return loadedArtworks.sorted { ($0.title ?? "") < ($1.title ?? "") }
    }
    
    private func fetchDetail(id: Int) async -> Artwork? {
        guard let url = URL(string: "\(baseURL)/objects/\(id)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try? JSONDecoder().decode(Artwork.self, from: data)
        } catch {
            return nil
        }
    }
}
