//
//  SingleCellPagedLayout.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/30/25.
//

import Foundation
import UIKit

public class CarouselCollectionViewLayout: UICollectionViewFlowLayout {
    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {

        guard let collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        // Identify the layoutAttributes of cells in the vicinity of where the scroll view will come to rest
        let targetRect = CGRect(origin: proposedContentOffset, size: collectionView.bounds.size)
        let visibleCellsLayoutAttributes = layoutAttributesForElements(in: targetRect)

        // Translate those cell layoutAttributes into potential (candidate) scrollView offsets
        let candidateOffsets: [CGFloat]? = visibleCellsLayoutAttributes?.map({ cellLayoutAttributes in
            if #available(iOS 11.0, *) {
                return cellLayoutAttributes.frame.origin.x - collectionView.contentInset.left - collectionView.safeAreaInsets.left - sectionInset.left
            } else {
                return cellLayoutAttributes.frame.origin.x - collectionView.contentInset.left - sectionInset.left
            }
        })

        // Now we need to work out which one of the candidate offsets is the best one
        let bestCandidateOffset: CGFloat

        if velocity.x > 0 {
            // If the scroll velocity was POSITIVE, then only consider cells/offsets to the RIGHT of the proposedContentOffset.x
            // Of the cells/offsets to the right, the NEAREST is the `bestCandidate`
            // If there is no nearestCandidateOffsetToLeft then we default to the RIGHT-MOST (last) of ALL the candidate cells/offsets
            //      (this handles the scenario where the user has scrolled beyond the last cell)
            let candidateOffsetsToRight = candidateOffsets?.toRight(ofProposedOffset: proposedContentOffset.x)
            let nearestCandidateOffsetToRight = candidateOffsetsToRight?.nearest(toProposedOffset: proposedContentOffset.x)
            bestCandidateOffset = nearestCandidateOffsetToRight ?? candidateOffsets?.last ?? proposedContentOffset.x
        }
        else if velocity.x < 0 {
            // If the scroll velocity was NEGATIVE, then only consider cells/offsets to the LEFT of the proposedContentOffset.x
            // Of the cells/offsets to the left, the NEAREST is the `bestCandidate`
            // If there is no nearestCandidateOffsetToLeft then we default to the LEFT-MOST (first) of ALL the candidate cells/offsets
            //      (this handles the scenario where the user has scrolled beyond the first cell)
            let candidateOffsetsToLeft = candidateOffsets?.toLeft(ofProposedOffset: proposedContentOffset.x)
            let nearestCandidateOffsetToLeft = candidateOffsetsToLeft?.nearest(toProposedOffset: proposedContentOffset.x)
            bestCandidateOffset = nearestCandidateOffsetToLeft ?? candidateOffsets?.first ?? proposedContentOffset.x
        }
        else {
            // If the scroll velocity was ZERO we consider all `candidate` cells (regarless of whether they are to the left OR right of the proposedContentOffset.x)
            // The cell/offset that is the NEAREST is the `bestCandidate`
            let nearestCandidateOffset = candidateOffsets?.nearest(toProposedOffset: proposedContentOffset.x)
            bestCandidateOffset = nearestCandidateOffset ??  proposedContentOffset.x
        }

        return CGPoint(x: bestCandidateOffset, y: proposedContentOffset.y)
    }

}

fileprivate extension Sequence where Iterator.Element == CGFloat {

    func toLeft(ofProposedOffset proposedOffset: CGFloat) -> [CGFloat] {

        return filter() { candidateOffset in
            return candidateOffset < proposedOffset
        }
    }

    func toRight(ofProposedOffset proposedOffset: CGFloat) -> [CGFloat] {

        return filter() { candidateOffset in
            return candidateOffset > proposedOffset
        }
    }

    func nearest(toProposedOffset proposedOffset: CGFloat) -> CGFloat? {

        guard let firstCandidateOffset = first(where: { _ in true }) else {
            // If there are no elements in the Sequence, return nil
            return nil
        }

        return reduce(firstCandidateOffset) { (bestCandidateOffset: CGFloat, candidateOffset: CGFloat) -> CGFloat in

            let candidateOffsetDistanceFromProposed = fabs(candidateOffset - proposedOffset)
            let bestCandidateOffsetDistancFromProposed = fabs(bestCandidateOffset - proposedOffset)

            if candidateOffsetDistanceFromProposed < bestCandidateOffsetDistancFromProposed {
                return candidateOffset
            }

            return bestCandidateOffset
        }
    }
}
