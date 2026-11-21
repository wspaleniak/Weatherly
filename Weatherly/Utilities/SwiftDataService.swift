//
//  SwiftDataService.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 21/11/2026.
//

import SwiftData

/// Provides generic operations for one SwiftData model type.
///
/// The service uses the container's main context and doesn't keep a separate
/// in-memory copy of fetched models. The main context automatically saves pending
/// inserts, updates, and deletes.
@MainActor
struct SwiftDataService<Model: PersistentModel> {
    private let modelContext: ModelContext

    /// Creates a service that operates on the main context of the supplied container.
    /// - Parameter modelContainer: The container that stores the model data.
    init(modelContainer: ModelContainer) {
        self.modelContext = modelContainer.mainContext
    }

    /// Fetches models matching the descriptor.
    /// - Parameter descriptor: The criteria and sort order for the fetch.
    /// - Returns: The models matching the descriptor.
    /// - Throws: An error if SwiftData can't perform the fetch.
    func fetch(
        _ descriptor: FetchDescriptor<Model> = FetchDescriptor<Model>()
    ) throws -> [Model] {
        try modelContext.fetch(descriptor)
    }

    /// Registers a model for insertion into the context.
    /// - Parameter model: The model to insert.
    func insert(_ model: Model) {
        modelContext.insert(model)
    }

    /// Registers a model for deletion from the context.
    /// - Parameter model: The model to delete.
    func delete(_ model: Model) {
        modelContext.delete(model)
    }
}
