import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FIND from "../contracts/FIND.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(merchAccount: Address, name: String, amount: UFix64) {

	let price : UFix64
	let finLeases : auth(FIND.LeaseOwner) &FIND.LeaseCollection
	let mainDapperUtilityCoinVault: auth(FungibleToken.Withdrawable) &DapperUtilityCoin.Vault
	let balanceBeforeTransfer: UFix64

	prepare(dapper: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account, acct: auth(BorrowValue, FIND.LeaseOwner) &Account) {
		self.price=FIND.calculateCost(name)
		self.mainDapperUtilityCoinVault = dapper.storage.borrow<auth(FungibleToken.Withdrawable) &DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
		self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.getBalance()
		self.finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("Could not borrow reference to find lease collection")
	}

	pre{
		merchAccount == 0x55459409d30274ee : "Merchant account is not .find"
		self.price == amount : "expected renew cost : ".concat(self.price.toString()).concat(" is not the same as calculated renew cost : ").concat(amount.toString())
	}

	execute{
		let payVault <- self.mainDapperUtilityCoinVault.withdraw(amount: self.price) as! @DapperUtilityCoin.Vault
		let finToken= self.finLeases.borrow(name)
		finToken.extendLeaseDapper(merchAccount: merchAccount, vault: <- payVault)
	}

	post {
		self.mainDapperUtilityCoinVault.getBalance() == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
}
