import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(merchAccount: Address, name: String, amount: UFix64) {

	let vaultRef : &DapperUtilityCoin.Vault?
	let leases : &FIND.LeaseCollection?
	let price : UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {

		self.price=FIND.calculateCost(name)
		log("The cost for registering this name is ".concat(self.price.toString()))
		self.vaultRef = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
		self.leases=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
	}

	pre{
		self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
		self.leases != nil : "Could not borrow reference to find lease collection"
		self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(amount.toString())
	}

	execute{
		let payVault <- self.vaultRef!.withdraw(amount: self.price) as! @DapperUtilityCoin.Vault
		self.leases!.registerDapper(merchAccount: merchAccount, name: name, vault: <- payVault)
	}
}
