import "FungibleToken"
import "FlowStorageFees"
import "FlowToken"

/*
FeeEstimator

Small contract that allows other contracts to estimate how much storage cost a resource might take up.
This is done by storing a resource in the FeeEstimator, recording the difference in available balance,
then returning the difference and the original item being estimated.

Consumers of this contract would then need to pop the resource out of the DepositEstimate resource to get it back
*/
access(all) contract FeeEstimator {
    access(all) resource DepositEstimate {
        access(all) var item: @AnyResource?
        access(all) var storageFee: UFix64

        init(item: @AnyResource, storageFee: UFix64) {
            self.item <- item
            self.storageFee = storageFee
        }

        access(all) fun withdraw(): @AnyResource {
            let r <- self.item <- nil
            return <-r!
        }
    }

    access(all) fun hasStorageCapacity(_ addr: Address, _ storageFee: UFix64): Bool {
        return FlowStorageFees.defaultTokenAvailableBalance(addr) > storageFee
    }

    access(all) fun estimateDeposit(
        item: @AnyResource,
    ): @DepositEstimate {
        let storageUsedBefore = FeeEstimator.account.storage.used
        FeeEstimator.account.storage.save(<-item, to: /storage/temp)
        let storageUsedAfter = FeeEstimator.account.storage.used

        let storageDiff = storageUsedAfter - storageUsedBefore
        let storageFee = FeeEstimator.storageUsedToFlowAmount(storageDiff)
        let loadedItem <- FeeEstimator.account.storage.load<@AnyResource>(from: /storage/temp)!
        let estimate <- create DepositEstimate(item: <-loadedItem, storageFee: storageFee)
        return <- estimate
    }

    access(all) fun storageUsedToFlowAmount(_ storageUsed: UInt64): UFix64 {
        let storageMB = FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(storageUsed)
        return FlowStorageFees.storageCapacityToFlow(storageMB)
    }

    init() {}
}
