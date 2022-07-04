import FIND from "../contracts/FIND.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(name: String, amount: UFix64) {

	let vaultRef : &FUSD.Vault?
	let bids : &FIND.BidCollection?

	prepare(account: AuthAccount) {

		
		let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)

		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			account.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let bidCollection = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			account.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			account.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
		}

		self.vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)
		self.bids = account.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)
	}

	pre{
		self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
		self.bids != nil : "Could not borrow reference to bid collection"
	}

	execute{
		let vault <- self.vaultRef!.withdraw(amount: amount) as! @FUSD.Vault
		self.bids!.increaseBid(name: name, vault: <- vault)
	}
}
