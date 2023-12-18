import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

	let vaultRef : &FUSD.Vault?
	let bidRef : &FIND.BidCollection?

	prepare(account: auth(BorrowValue) &Account) {

		self.vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)
		self.bidRef = account.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)
	}

	pre{
		self.vaultRef != nil : "Could not borrow reference to the fusdVault!" 
		self.bidRef != nil : "Could not borrow reference to the bid collection!" 
	}

	execute {
		let vault <- self.vaultRef!.withdraw(amount: amount) as! @FUSD.Vault
		self.bidRef!.bid(name: name, vault: <- vault)
	}
}
