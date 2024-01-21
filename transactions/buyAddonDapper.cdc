import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FIND from "../contracts/FIND.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"


transaction(merchAccount: Address, name: String, addon:String, amount:UFix64) {

	let finLeases : auth(FIND.LeaseOwner) &FIND.LeaseCollection
	let mainDapperUtilityCoinVault: auth(FungibleToken.Withdrawable) &DapperUtilityCoin.Vault
	let balanceBeforeTransfer: UFix64

	prepare(dapper: auth(BorrowValue) &Account, account: auth(BorrowValue) &Account) {
		self.mainDapperUtilityCoinVault = dapper.storage.borrow<auth(FungibleToken.Withdrawable) &DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
		self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.getBalance()
		self.finLeases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("Could not borrow reference to find lease collection")
	}

	execute {
		let vault <- self.mainDapperUtilityCoinVault.withdraw(amount: amount) as! @DapperUtilityCoin.Vault
		self.finLeases.buyAddonDapper(merchAccount: merchAccount, name: name, addon: addon, vault: <- vault)
	}

	post {
		self.mainDapperUtilityCoinVault.getBalance() == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
}

