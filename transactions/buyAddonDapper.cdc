import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(merchAccount: Address, name: String, addon:String, amount:UFix64) {

	let leases : &FIND.LeaseCollection?
	let vaultRef : &DapperUtilityCoin.Vault? 

	prepare(dapper: AuthAccount, account: AuthAccount) {

		self.leases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
		self.vaultRef = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)

	}

	pre{
		self.leases != nil : "Could not borrow reference to the leases collection"
		self.vaultRef != nil : "Could not borrow reference to the dapper coin vault!"
	}

	execute {
		let vault <- self.vaultRef!.withdraw(amount: amount) as! @DapperUtilityCoin.Vault
		self.leases!.buyAddonDapper(merchAccount: merchAccount, name: name, addon: addon, vault: <- vault)
	}
}

