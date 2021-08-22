import FiNS from "../contracts/FiNS.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(tag: String, amount: UFix64) {
	prepare(account: AuthAccount) {


		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		 
		let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)

		let leaseCollection = account.getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)
		if !leaseCollection.check() {
			account.save(<- FiNS.createEmptyLeaseCollection(), to: FiNS.LeaseStoragePath)
			account.link<&{FiNS.LeaseCollectionPublic}>( FiNS.LeasePublicPath, target: FiNS.LeaseStoragePath)
		}

		let bidCollection = account.getCapability<&{FiNS.BidCollectionPublic}>(FiNS.BidPublicPath)
		if !bidCollection.check() {
			account.save(<- FiNS.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FiNS.BidStoragePath)
			account.link<&{FiNS.BidCollectionPublic}>( FiNS.BidPublicPath, target: FiNS.BidStoragePath)
		}


		let vault <- vaultRef.withdraw(amount: amount) as! @FUSD.Vault
		let bids = account.borrow<&FiNS.BidCollection>(from: FiNS.BidStoragePath)!
		bids.bid(tag: tag, vault: <- vault)

	}
}
