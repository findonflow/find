import FungibleToken from "./FungibleToken.cdc"
import FlowStorageFees from "./FlowStorageFees.cdc"
import FlowToken from "./FlowToken.cdc"

/*
    FeeEstimator
    
    Small contract that allows other contracts to estimate how much storage cost a resource might take up.
    This is done by storing a resource in the FeeEstimator, recording the difference in available balance,
    then returning the difference and the original item being estimated.

    Consumers of this contract would then need to pop the resource out of the DepositEstimate resource to get it back
 */
pub contract FeeEstimator {
    pub resource DepositEstimate {
        pub var item: @AnyResource?
        pub var storageFee: UFix64

        init(item: @AnyResource, storageFee: UFix64) {
            self.item <- item
            self.storageFee = storageFee
        }

        pub fun withdraw(): @AnyResource {
            let resource <- self.item <- nil
            return <-resource!
        }

        destroy() {
            pre {
                self.item == nil: "cannot destroy with non-null item"
            }

            destroy self.item
        }
    }

    pub fun hasStorageCapacity(_ addr: Address, _ storageFee: UFix64): Bool {
        return FlowStorageFees.defaultTokenAvailableBalance(addr) > storageFee
    }

    pub fun estimateDeposit(
        item: @AnyResource,
    ): @DepositEstimate {
        let storageUsedBefore = FeeEstimator.account.storageUsed
        FeeEstimator.account.save(<-item, to: /storage/temp)
        let storageUsedAfter = FeeEstimator.account.storageUsed

        let storageDiff = storageUsedAfter - storageUsedBefore
        let storageFee = FeeEstimator.storageUsedToFlowAmount(storageDiff)
        let loadedItem <- FeeEstimator.account.load<@AnyResource>(from: /storage/temp)!
        let estimate <- create DepositEstimate(item: <-loadedItem, storageFee: storageFee)
        return <- estimate
    }

    pub fun storageUsedToFlowAmount(_ storageUsed: UInt64): UFix64 {
        let storageMB = FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(storageUsed)
        return FlowStorageFees.storageCapacityToFlow(storageMB)
    }

    init() {}
}