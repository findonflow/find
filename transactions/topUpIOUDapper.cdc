import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import IOweYou from "../contracts/IOweYou.cdc"
import DapperIOweYou from "../contracts/DapperIOweYou.cdc"


transaction(id: UInt64, amount: UFix64) {


	let walletReference : &FungibleToken.Vault
	let walletBalance : UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {
		let collectionRef = account.borrow<&DapperIOweYou.Collection>(from: DapperIOweYou.CollectionStoragePath)!
		let vaultType = collectionRef.borrowIOU(id).vaultType.identifier

		let ft = FTRegistry.getFTInfo(vaultType) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(vaultType))
		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath)!
		self.walletBalance = self.walletReference.balance
		let vault <- self.walletReference.withdraw(amount: amount)

		collectionRef.topUp(id: id, vault: <- vault)
	}

	post{
		self.walletBalance == self.walletReference.balance : "Token leakage"
	}
}

