//
//  FavoritesView.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 22/11/2026.
//

import FactoryKit
import SwiftUI

/// Shows favorite cities, recent searches, and search results.
///
/// Compact layouts push favorite details, while regular layouts show the selected
/// city in the split view's detail column.
@MainActor
struct FavoritesView: View {
    
    // MARK: - Properties
    
    /// The shared router for push and modal navigation.
    @InjectedObservable(\.appRouter)
    private var router

    /// The horizontal size class used to adapt split-view navigation.
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    /// Supplies favorite, search, and persistence state to the view.
    @Bindable
    var viewModel: FavoritesViewModel

    /// Indicates whether the native search interface is active.
    @State
    private var isSearchPresented = false
    
    // MARK: - Bindings
    
    /// Connects the navigation stack path to the shared router.
    private var stackBinding: Binding<[AppRouter.Screen]> {
        Binding(
            get: { router.stack },
            set: { router.setStack($0) }
        )
    }
    
    /// Connects modal presentation to the shared router.
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
    
    /// Forwards native search-field edits to the view model's input validation.
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { viewModel.updateSearchText($0) }
        )
    }
    
    // MARK: - Body
    
    /// Builds the split navigation layout and presents modal search details.
    var body: some View {
        NavigationSplitView {
            NavigationStack(path: stackBinding) {
                Group {
                    if isSearchPresented {
                        searches
                    } else {
                        favorites
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .background(background)
                .searchable(
                    text: searchTextBinding,
                    isPresented: $isSearchPresented,
                    placement: .sidebar,
                    prompt: Text("Search.prompt")
                )
            }
            .navigationDestination(for: AppRouter.Screen.self) { _ in
                if let city = viewModel.selectedFavoriteCity {
                    let viewModel = DetailsViewModel(
                        city: city,
                        source: .push
                    )
                    DetailsView(viewModel: viewModel)
                }
            }
        } detail: {
            if let city = viewModel.selectedFavoriteCity {
                let viewModel = DetailsViewModel(
                    city: city,
                    source: .push
                )
                DetailsView(viewModel: viewModel)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .animation(nil, value: isSearchPresented)
        .animation(.smooth, value: viewModel.state)
        .animation(.smooth, value: viewModel.searchState)
        .onChange(of: isSearchPresented) { _, _ in
            viewModel.updateSearchText("")
        }
        .onChange(of: horizontalSizeClass) { _, sizeClass in
            switch sizeClass {
            case .some(.regular):
                router.setStack([])
            case .some(.compact):
                if viewModel.selectedFavoriteCity != nil && router.stack.isEmpty {
                    router.push(.details)
                }
            default:
                break
            }
        }
        .onChange(of: router.stack) { oldValue, newValue in
            if horizontalSizeClass == .compact, !oldValue.isEmpty, newValue.isEmpty {
                viewModel.refresh()
            }
        }
        .onChange(of: router.presented) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                viewModel.selectedSearchCity = nil
                viewModel.refresh()
            }
        }
        .sheet(item: presentedBinding) { _ in
            if let city = viewModel.selectedSearchCity {
                NavigationStack {
                    let viewModel = DetailsViewModel(
                        city: city,
                        source: .modal { isSearchPresented = false }
                    )
                    DetailsView(viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Subviews

extension FavoritesView {
    /// Displays the loading state, empty state, or persisted favorite cities.
    @ViewBuilder
    private var favorites: some View {
        switch viewModel.state {
        case .downloading:
            ProgressView {
                Text("Favorites.loading")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .downloaded(let cities):
            if cities.isEmpty {
                unavailable(
                    image: "star",
                    title: "Favorites.empty.title",
                    description: "Favorites.empty.description"
                )
            } else {
                List(cities) { city in
                    FavoritesRowView(
                        city: city,
                        onTap: {
                            viewModel.selectedFavoriteCity = city.city
                            if horizontalSizeClass == .compact {
                                router.push(.details)
                            }
                        },
                        onRemove: {
                            viewModel.remove(city: city.city)
                        }
                    )
                }
            }
        }
    }
    
    /// Displays recent searches, network results, empty results, or a search error.
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
                List {
                    Section {
                        ForEach(cities) { city in
                            SearchRowView(
                                city: city,
                                onTap: {
                                    viewModel.selectedSearchCity = city
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
            }
        case .downloaded(let cities):
            if cities.isEmpty {
                unavailable(
                    image: "magnifyingglass",
                    title: "Search.results.empty.title",
                    description: "Search.results.empty.description"
                )
            } else {
                List {
                    Section {
                        ForEach(cities) { city in
                            SearchRowView(
                                city: city,
                                onTap: {
                                    viewModel.selectedSearchCity = city
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
            }
        case .error:
            unavailable(
                image: "exclamationmark.triangle",
                title: "Common.error.title",
                description: "Common.error.description"
            )
        }
    }
    
    /// Builds an unavailable-content message with the supplied symbol and localized text.
    ///
    /// - Parameters:
    ///   - image: The SF Symbol shown with the message.
    ///   - title: The localized title for the unavailable state.
    ///   - description: The localized explanation for the unavailable state.
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
    
    /// The gradient displayed behind the favorites and search lists.
    private var background: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.8),
                Color.blue.opacity(0.4),
                Color.indigo.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
