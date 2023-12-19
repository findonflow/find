import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(merchAccount: Address, name: String, amount: UFix64) {

	let finLeases : &FIND.LeaseCollection
	let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
	let balanceBeforeTransfer: UFix64
	let price : UFix64

	prepare(dapper: auth(BorrowValue) &Account, account: auth(BorrowValue) &Account) {

		self.price=FIND.calculateCost(name)
		log("The cost for registering this name is ".concat(self.price.toString()))
		self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
		self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance
		self.finLeases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("Could not borrow reference to find lease collection")
	}

	pre{
		merchAccount == 0x4748780c8bf65e19 : "Merchant account is not .find"
		self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(amount.toString())
	}

	execute{
		let payVault <- self.mainDapperUtilityCoinVault.withdraw(amount: self.price) as! @DapperUtilityCoin.Vault
		self.finLeases.registerDapper(merchAccount: merchAccount, name: name, vault: <- payVault)
	}

	post {
		self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
}
