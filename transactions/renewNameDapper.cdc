import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(merchAccount: Address, name: String, amount: UFix64) {

	let price : UFix64
	let vaultRef : &DapperUtilityCoin.Vault? 
	let finLeases : &FIND.LeaseCollection? 

	prepare(dapper: AuthAccount, acct: AuthAccount) {
		self.price=FIND.calculateCost(name)
		self.vaultRef = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
		self.finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
	}

	pre{
		self.price == amount : "expected renew cost : ".concat(self.price.toString()).concat(" is not the same as calculated renew cost : ").concat(amount.toString())
		self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
		self.finLeases != nil : "Could not borrow reference to find lease collection"
	}

	execute{
		let payVault <- self.vaultRef!.withdraw(amount: self.price) as! @DapperUtilityCoin.Vault
		let finToken= self.finLeases!.borrow(name)
		finToken.extendLeaseDapper(merchAccount: merchAccount, vault: <- payVault)
	}
}
