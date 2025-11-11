//
//  File.swift
//  FilenFoto
//
//  Created by Hunter Han on 9/21/25.
//

import CoreData
import Foundation

extension PhotoSyncController {
    func runProviders(for workingAsset: WorkingSetFotoAsset) async {
        let providerManagedContext = FFCoreDataManager.shared.newChildContext()
        let fotoAsset = await workingAsset.asset(in: providerManagedContext)

        guard let fotoAsset else {
            logger.error("FotoAsset was nil")
            return
        }

        let providerStatuses = fotoAsset.providerStatuses as? Set<ProviderStatus>
        
        let providerProgress = Progress(totalUnitCount: AvailableProvider.totalProgressWeight)
        progress.addChild(providerProgress, withPendingUnitCount: AvailableProvider.totalProgressWeight)

        for potentialProvider in AvailableProvider.allCases {
            let providerDelegate = potentialProvider.provider
            var currentProviderStatus: ProviderStatus

            if let existingProviderStatus = providerStatuses?.first(where: { $0.provider == potentialProvider }) {
                currentProviderStatus = existingProviderStatus
            } else {
                currentProviderStatus = ProviderStatus(context: providerManagedContext)
                currentProviderStatus.parentAsset = fotoAsset
                currentProviderStatus.provider = potentialProvider
                currentProviderStatus.state = .notStarted
            }

            func execute(perform action: @escaping () async throws -> ProviderCompletion?) async throws {
                var completion: ProviderCompletion?

                do {
                    completion = try await action()
                    currentProviderStatus.state = .succeded
                    currentProviderStatus.failureMessage = nil
                    currentProviderStatus.version = providerDelegate.version
                } catch let error as FilenFotoError {
                    currentProviderStatus.state = .failed
                    currentProviderStatus.failureMessage = "\(error.errorDescription ?? "No error description found")"
                } catch {
                    currentProviderStatus.state = .failed
                    currentProviderStatus.failureMessage = "\(error.localizedDescription)"
                }

                try providerManagedContext.save()
                await FFCoreDataManager.shared.saveContextIfNeeded()
                if let completion {
                    completion()
                }
            }

            do {
                switch currentProviderStatus.state {
                case .notStarted:
                    try await execute {
                        try await providerDelegate.initiateProtocol(for: workingAsset, with: fotoAsset)
                    }
                case .failed:
                    try await execute {
                        try await providerDelegate.retryFailedActions(for: workingAsset, with: fotoAsset)
                    }
                case .succeded:
                    for versionUpgrade in currentProviderStatus.version..<providerDelegate.version {
                        try await execute {
                            try await providerDelegate.incrementlyMigrate(workingAsset, with: fotoAsset, from: versionUpgrade)
                        }
                    }

                    if providerDelegate.version != currentProviderStatus.version {
                        logger.critical(
                            "The version after migration is not updated or is different from the current provider version. Current version: \(currentProviderStatus.version), Current provider version: \(providerDelegate.version)"
                        )
                    }
                }
                
                providerProgress.completedUnitCount += potentialProvider.progressWeight
            } catch {
                logger.error("An unrecoverable error occurred in the photoSyncController: \(error)")

                providerProgress.cancel()
                providerProgress.completedUnitCount += providerProgress.totalUnitCount
                return
            }
        }
    }

}
