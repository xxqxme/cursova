import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ArtViewModel()
    
    @State private var searchPath = NavigationPath()
    @State private var selectedTab = 0
    
    let backgroundGradient = LinearGradient(
        colors: [Color.indigo.opacity(0.2), Color.purple.opacity(0.1), Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        let tabBinding = Binding<Int>(
            get: { selectedTab },
            set: { tappedTab in
                if tappedTab == selectedTab && tappedTab == 0 {
                    searchPath = NavigationPath()
                }
                selectedTab = tappedTab
            }
        )
        
        TabView(selection: tabBinding) {
            SearchView(vm: vm, background: backgroundGradient, path: $searchPath)
                .tabItem {
                    Label("Пошук", systemImage: "magnifyingglass")
                }
                .tag(0)
            
            FavoritesView(vm: vm, background: backgroundGradient)
                .tabItem {
                    Label("Колекція", systemImage: "star.square.on.square.fill")
                }
                .tag(1)
        }
        .accentColor(.indigo)
    }
}

struct SearchView: View {
    @ObservedObject var vm: ArtViewModel
    var background: LinearGradient
    
    @Binding var path: NavigationPath
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        TextField("Пошук", text: $vm.query)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .focused($isFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                Task { await vm.search() }
                            }
                            .overlay(
                                HStack {
                                    Spacer()
                                    if !vm.query.isEmpty {
                                        Button(action: { vm.query = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.trailing, 8)
                                    }
                                }
                            )
                        
                        Button {
                            Task { await vm.search() }
                            isFocused = false
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.indigo)
                                .cornerRadius(12)
                                .shadow(radius: 3)
                        }
                    }
                    .padding()
                    
                    if vm.isLoading {
                        Spacer()
                        ProgressView("Завантаження")
                            .tint(.indigo)
                            .scaleEffect(1.2)
                        Spacer()
                    } else if let err = vm.errorMessage {
                        Spacer()
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(err).padding().foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(vm.artworks) { art in
                                    NavigationLink(value: art) {
                                        GlassArtworkCard(art: art)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Музей")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Artwork.self) { art in
                DetailView(artwork: art, vm: vm)
            }
        }
    }
}

struct FavoritesView: View {
    @ObservedObject var vm: ArtViewModel
    var background: LinearGradient
    
    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()
                
                if vm.favorites.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.indigo.opacity(0.3))
                        Text("Ваша галерея порожня")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(vm.favorites) { art in
                                NavigationLink(value: art) {
                                    GlassArtworkCard(art: art)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Моя Колекція")
            .navigationDestination(for: Artwork.self) { art in
                DetailView(artwork: art, vm: vm)
            }
        }
    }
}

struct GlassArtworkCard: View {
    let art: Artwork
    
    var body: some View {
        HStack(spacing: 15) {
            if let thumb = art.primaryImageSmall, let url = URL(string: thumb) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.indigo.opacity(0.1)
                    }
                }
                .frame(width: 70, height: 70)
                .cornerRadius(10)
                .clipped()
            } else {
                ZStack {
                    Color.indigo.opacity(0.05)
                    Image(systemName: "photo")
                        .foregroundColor(.indigo.opacity(0.3))
                }
                .frame(width: 70, height: 70)
                .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(art.title ?? "Без назви")
                    .font(.system(.headline, design: .serif))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(art.artistDisplayName ?? "Невідомий автор")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.5))
                .font(.caption)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
