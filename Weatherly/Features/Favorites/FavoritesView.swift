//
//  FavoritesView.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 22/11/2026.
//

import FactoryKit
import SwiftUI

@MainActor
struct FavoritesView: View {
    
    // MARK: - Properties
    
    @InjectedObservable(\.appRouter)
    private var router
    
    @Bindable
    var viewModel: FavoritesViewModel

    @State
    private var isSearchPresented = false
    
    // MARK: - Bindings
    
    private var stackBinding: Binding<[AppRouter.Screen]> {
        Binding(
            get: { router.stack },
            set: { router.setStack($0) }
        )
    }
    
    private var presentedBinding: Binding<AppRouter.Screen?> {
        Binding(
            get: { router.presented },
            set: { screen in
                if let screen {
                    router.present(screen)
                } else {
                    router.dismiss()
                }
            }
        )
    }
    
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { viewModel.updateSearchText($0) }
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView {
            NavigationStack(path: stackBinding) {
                List {
                    if isSearchPresented {
                        searches
                    } else {
                        favorites
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(background)
                .navigationTitle(Text("Favorites.title"))
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: searchTextBinding,
                    isPresented: $isSearchPresented,
                    placement: .sidebar,
                    prompt: Text("Search.prompt")
                )
            }
            .navigationDestination(for: AppRouter.Screen.self) { _ in
                DetailsView()
            }
        } detail: {
            DetailsView()
        }
        .navigationSplitViewStyle(.balanced)
        .background(background)
        .animation(nil, value: isSearchPresented)
        .onChange(of: router.stack) { oldValue, newValue in
            if !oldValue.isEmpty && newValue.isEmpty {
                viewModel.refresh()
            }
        }
        .onChange(of: router.presented) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                viewModel.refresh()
            }
        }
        .onChange(of: isSearchPresented) { _, _ in
            viewModel.updateSearchText("")
        }
        .sheet(item: presentedBinding) { _ in
            DetailsView()
        }
    }
}

// MARK: - Subviews

extension FavoritesView {
    @ViewBuilder
    private var favorites: some View {
        switch viewModel.state {
        case .downloading:
            ProgressView {
                Text("Favorites.loading")
            }
        case .downloaded(let cities):
            if cities.isEmpty {
                unavailable(
                    image: "star",
                    title: "Favorites.empty.title",
                    description: "Favorites.empty.description"
                )
            } else {
                ForEach(cities) { city in
                    FavoritesRowView(
                        city: city,
                        onTap: { router.push(.details) }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var searches: some View {
        switch viewModel.searchState {
        case .lastSearched(let cities):
            if cities.isEmpty {
                unavailable(
                    image: "clock.arrow.circlepath",
                    title: "Search.recent.empty.title",
                    description: "Search.recent.empty.description"
                )
            } else {
                Section {
                    ForEach(cities) { city in
                        SearchRowView(
                            city: city,
                            onTap: {
                                viewModel.record(city: city)
                                router.present(.details)
                            }
                        )
                    }
                } header: {
                    Text("Search.recent.section.title")
                        .font(.subheadline)
                        .textCase(.uppercase)
                }
            }
        case .downloaded(let cities):
            if cities.isEmpty {
                unavailable(
                    image: "magnifyingglass",
                    title: "Search.results.empty.title",
                    description: "Search.results.empty.description"
                )
            } else {
                Section {
                    ForEach(cities) { city in
                        SearchRowView(
                            city: city,
                            onTap: {
                                viewModel.record(city: city)
                                router.present(.details)
                            }
                        )
                    }
                } header: {
                    Text("Search.results.section.title")
                        .font(.subheadline)
                        .textCase(.uppercase)
                }
            }
        case .error:
            unavailable(
                image: "exclamationmark.triangle",
                title: "Common.error.title",
                description: "Common.error.description"
            )
        }
    }
    
    private func unavailable(
        image: String,
        title: LocalizedStringResource,
        description: LocalizedStringResource
    ) -> some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: image)
                    .font(.headline)
            }
        } description: {
            Text(description)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    private var background: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.75),
                Color.blue.opacity(0.45),
                Color.indigo.opacity(0.75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
