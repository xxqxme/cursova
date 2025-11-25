import SwiftUI

struct DetailView: View {
    let artwork: Artwork

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let urlString = artwork.primaryImage, let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(maxWidth: .infinity, minHeight: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        case .failure:
                            // Fallback to small image if large fails
                            if let thumb = artwork.primaryImageSmall, let turl = URL(string: thumb) {
                                AsyncImage(url: turl) { p in
                                    if let img = try? p.image {
                                        img
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } else {
                                        Color.gray.frame(height: 200)
                                    }
                                }
                            } else {
                                Color.gray.frame(height: 200)
                            }
                        @unknown default:
                            Color.gray.frame(height: 200)
                        }
                    }
                } else if let thumb = artwork.primaryImageSmall, let url = URL(string: thumb) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fit)
                        } else if phase.error != nil {
                            Color.gray.frame(height: 200)
                        } else {
                            ProgressView().frame(height: 200)
                        }
                    }
                } else {
                    Color.gray.frame(height: 200)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(artwork.title ?? "Без назви")
                        .font(.title2)
                        .bold()
                    Text("Автор: \(artwork.artistDisplayName ?? "Невідомий")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let date = artwork.objectDate, !date.isEmpty {
                        Text("Дата: \(date)")
                            .font(.subheadline)
                    }
                    if let medium = artwork.medium, !medium.isEmpty {
                        Text("Матеріал: \(medium)")
                            .font(.subheadline)
                    }
                    if let dept = artwork.department, !dept.isEmpty {
                        Text("Відділ: \(dept)")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
        }
        .navigationTitle(artwork.title ?? "Деталі")
        .navigationBarTitleDisplayMode(.inline)
    }
}
