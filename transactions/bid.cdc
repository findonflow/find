import FIN from "../contracts/FIN.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(tag: String, amount: UFix64) {
	prepare(account: AuthAccount) {


		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let seller=FIN.lookup(tag)!.owner
		
		let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)

		let leaseCollection = account.getCapability<&{FIN.LeaseCollectionPublic}>(FIN.LeasePublicPath)
		if !leaseCollection.check() {
			account.save(<- FIN.createEmptyLeaseCollection(), to: FIN.LeaseStoragePath)
			account.link<&{FIN.LeaseCollectionPublic}>( FIN.LeasePublicPath, target: FIN.LeaseStoragePath)
		}

		let bidCollection = account.getCapability<&FIN.BidCollection>(FIN.BidPrivatePath)
		if !bidCollection.check() {
			account.save(<- FIN.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIN.BidStoragePath)
			account.link<&{FIN.BidCollectionPublic}>( FIN.BidPublicPath, target: FIN.BidStoragePath)
			account.link<&FIN.BidCollection>( FIN.BidPrivatePath, target: FIN.BidStoragePath)
		}

		let vault <- vaultRef.withdraw(amount: amount) as! @FUSD.Vault
		FIN.bid(tag: tag, vault: <- vault, bids: bidCollection)
	}
}
