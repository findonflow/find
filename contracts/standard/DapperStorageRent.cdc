import FungibleToken from "./FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"

/// DapperStorageRent
/// Provide a means for accounts storage TopUps. To be used during transaction execution.
pub contract DapperStorageRent {

  pub let DapperStorageRentAdminStoragePath: StoragePath

  /// Threshold of storage required to trigger a refill
  access(contract) var StorageRentRefillThreshold: UInt64
  /// List of all refilledAccounts
  access(contract) var RefilledAccounts: [Address]
  /// Detailed account information of refilled accounts
  access(contract) var RefilledAccountInfos: {Address: RefilledAccountInfo}
  /// List of all blockedAccounts
  access(contract) var BlockedAccounts: [Address]
  /// Blocks required between refill attempts
  access(contract) var RefillRequiredBlocks: UInt64

  /// Event emitted when an Admin blocks an address
  pub event BlockedAddress(_ address: [Address])
  /// Event emitted when a Refill is successful
  pub event Refuelled(_ address: Address)
  /// Event emitted when a Refill is not successful
  pub event RefilledFailed(address: Address, reason: String)

  /// getStorageRentRefillThreshold
  /// Get the current StorageRentRefillThreshold
  ///
  /// @return UInt64 value of the current StorageRentRefillThreshold value
  access(all) getStorageRentRefillThreshold(): UInt64 {
    return self.StorageRentRefillThreshold
  }

  /// getRefilledAccounts
  /// Get the current StorageRentRefillThreshold
  ///
  /// @return List of refilled Accounts
  access(all) getRefilledAccounts(): [Address] {
    return self.RefilledAccounts
  }

  /// getBlockedAccounts
  /// Get the current StorageRentRefillThreshold
  ///
  /// @return List of blocked accounts
  access(all) getBlockedAccounts() : [Address] {
    return self.BlockedAccounts
  }

  /// getRefilledAccountInfos
  /// Get the current StorageRentRefillThreshold
  ///
  /// @return Address: RefilledAccountInfo mapping
  access(all) getRefilledAccountInfos(): {Address: RefilledAccountInfo} {
    return self.RefilledAccountInfos
  }

  /// getRefillRequiredBlocks
  /// Get the current StorageRentRefillThreshold
  ///
  /// @return UInt64 value of the current RefillRequiredBlocks value
  access(all) getRefillRequiredBlocks(): UInt64 {
    return self.RefillRequiredBlocks
  }


  access(all) fundedRefill(address: Address, tokens: @FungibleToken.Vault) {
		destroy tokens

		/*
      let privateForwardingSenderRef = self.account.storage.borrow<&PrivateReceiverForwarder.Sender>(from: PrivateReceiverForwarder.SenderStoragePath)!
      privateForwardingSenderRef!.sendPrivateTokens(address,tokens:<-tokens)
			*/
  }


  /// tryRefill
  /// Attempt to refill an accounts storage capacity if it has dipped below threshold and passes other checks.
  ///
  /// @param address: Address to attempt a storage refill on
  access(all) tryRefill(_ address: Address) {
		/*
    let REFUEL_AMOUNT = 0.06;

    self.cleanExpiredRefilledAccounts(10)

    // Get the Flow Token reciever of the address
    let recipient = getAccount(address)
    let receiverRef = recipient.getCapability<&PrivateReceiverForwarder.Forwarder>(PrivateReceiverForwarder.PrivateReceiverPublicPath).borrow()

    // Sliently fail if the receiverRef is nill
    if receiverRef == nil || receiverRef!.owner == nil {
      emit RefilledFailed(address: address, reason: "Couldn't borrow the Accounts flowTokenVault")
      return
    }

    // Sliently fail if the account has already be refueled within the block allowance
    if self.RefilledAccountInfos[address] != nil && getCurrentBlock().height - self.RefilledAccountInfos[address]!.atBlock < self.RefillRequiredBlocks {
      emit RefilledFailed(address: address, reason: "RefillRequiredBlocks")
      return
    }

    // Get the users storage capacity and usage values
    var low: UInt64 = recipient.storageUsed
    var high: UInt64 = recipient.storageCapacity

    if high < low {
      high <-> low
    }

    // Sliently fail if the account has been blocked from receiving refills
    if DapperStorageRent.getBlockedAccounts().contains(address) {
      emit RefilledFailed(address: address, reason: "Address is Blocked")
      return
    }

    // If the user is below the threshold PrivateReceiverForwarder will send 0.06 Flow tokens for about 6MB of storage
    if high - low < self.StorageRentRefillThreshold {
      let vaultRef = self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
      if vaultRef == nil {
        emit RefilledFailed(address: address, reason: "Couldn't borrow the Accounts FlowToken.Vault")
        return
      }

      let privateForwardingSenderRef = self.account.storage.borrow<&PrivateReceiverForwarder.Sender>(from: PrivateReceiverForwarder.SenderStoragePath)
      if privateForwardingSenderRef == nil {
        emit RefilledFailed(address: address, reason: "Couldn't borrow the Accounts PrivateReceiverForwarder")
        return
      }

      // Check to make sure the payment vault has sufficient funds
      if let vaultBalanceRef = self.account.getCapability(/public/flowTokenBalance).borrow<&FlowToken.Vault{FungibleToken.Balance}>() {
        if vaultBalanceRef.balance <= REFUEL_AMOUNT {
          emit RefilledFailed(address: address, reason: "Insufficient balance to refuel")
          return
        }
      } else {
        emit RefilledFailed(address: address, reason: "Couldn't borrow flowToken balance")
        return
      }

      // 0.06 = 6MB of storage, or ~20k NBA TS moments
      privateForwardingSenderRef!.sendPrivateTokens(address,tokens:<-vaultRef!.withdraw(amount: REFUEL_AMOUNT))
      self.addRefilledAccount(address)
      emit Refuelled(address)
    } else {
      emit RefilledFailed(address: address, reason: "Address is not below StorageRentRefillThreshold")
    }
		*/
  }

  /// checkEligibility
  ///
  /// @param address: Address to check eligibility on
  /// @return Boolean valued based on if the provided address is below the storage threshold
  access(all) checkEligibility(_ address: Address): Bool {
    if self.RefilledAccountInfos[address] != nil && getCurrentBlock().height - self.RefilledAccountInfos[address]!.atBlock < self.RefillRequiredBlocks {
       return false
    }
    let acct = getAccount(address)
    var high: UInt64 = acct.storageCapacity
    var low: UInt64 = acct.storageUsed
    if high < low {
      high <-> low
    }

    if high - low >= self.StorageRentRefillThreshold {
      return false
    }

    return true
  }

  /// addRefilledAccount
  ///
  /// @param address: Address to add to RefilledAccounts/RefilledAccountInfos
  access(contract) fun addRefilledAccount(_ address: Address) {
    if self.RefilledAccountInfos[address] != nil {
      self.RefilledAccounts.remove(at: self.RefilledAccountInfos[address]!.index)
    }

    self.RefilledAccounts.append(address)
    self.RefilledAccountInfos[address] = RefilledAccountInfo(self.RefilledAccounts.length-1, getCurrentBlock().height)
  }

  /// cleanExpiredRefilledAccounts
  /// public method to clean up expired accounts based on current block height
  ///
  /// @param batchSize: Int to set the batch size of the cleanup
  access(all) cleanExpiredRefilledAccounts(_ batchSize: Int) {
    var index = 0
    while index < batchSize && self.RefilledAccounts.length > index {
      if self.RefilledAccountInfos[self.RefilledAccounts[index]] != nil &&
        getCurrentBlock().height - self.RefilledAccountInfos[self.RefilledAccounts[index]]!.atBlock < self.RefillRequiredBlocks {
        break
      }

      self.RefilledAccountInfos.remove(key: self.RefilledAccounts[index])
      self.RefilledAccounts.remove(at: index)
      index = index + 1
    }
  }

  /// RefilledAccountInfo struct
  /// Holds the block number it was refilled at
  pub struct RefilledAccountInfo {
    pub let atBlock: UInt64
    pub let index: Int

    init(_ index: Int, _ atBlock: UInt64) {
      self.index = index
      self.atBlock = atBlock
    }
  }

  /// Admin resource
  /// Used to set different configuration levers such as StorageRentRefillThreshold, RefillRequiredBlocks, and BlockedAccounts
  pub resource Admin {
    access(all) setStorageRentRefillThreshold(_ threshold: UInt64) {
      DapperStorageRent.StorageRentRefillThreshold = threshold
    }

    access(all) setRefillRequiredBlocks(_ blocks: UInt64) {
      DapperStorageRent.RefillRequiredBlocks = blocks
    }

    access(all) blockAddress(_ address: Address) {
        if !DapperStorageRent.getBlockedAccounts().contains(address) {
            DapperStorageRent.BlockedAccounts.append(address)
            emit BlockedAddress(DapperStorageRent.getBlockedAccounts())
        }
    }

    access(all) unblockAddress(_ address: Address) {
        if DapperStorageRent.getBlockedAccounts().contains(address) {
            let position = DapperStorageRent.BlockedAccounts.firstIndex(of: address) ?? panic("Trying to unblock an address that is not blocked.")
            if position != nil {
                DapperStorageRent.BlockedAccounts.remove(at: position)
                emit BlockedAddress(DapperStorageRent.getBlockedAccounts())
            }
        }
    }
  }

  // DapperStorageRent init
  init() {
    self.DapperStorageRentAdminStoragePath = /storage/DapperStorageRentAdmin
    self.StorageRentRefillThreshold = 5000
    self.RefilledAccounts = []
    self.RefilledAccountInfos = {}
    self.RefillRequiredBlocks = 86400
    self.BlockedAccounts = []

    let admin <- create Admin()
    self.account.storage.save(<-admin, to: self.DapperStorageRentAdminStoragePath)
  }
}

