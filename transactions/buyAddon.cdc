import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String, addon:String, amount:UFix64) {

	let leases : &FIND.LeaseCollection?
	let vaultRef : &FUSD.Vault? 

	prepare(account: AuthAccount) {

		self.leases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
		self.vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)

	}

	pre{
		self.leases != nil : "Could not borrow reference to the leases collection"
		self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
	}

	execute {
		let vault <- self.vaultRef!.withdraw(amount: amount) as! @FUSD.Vault
		self.leases!.buyAddon(name: name, addon: addon, vault: <- vault)
	}
}

