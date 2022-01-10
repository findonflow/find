import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String, addon:String, amount:UFix64) {
	prepare(account: AuthAccount) {

		let leases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!

		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the fusdVault!")
		let vault <- vaultRef.withdraw(amount: amount) as! @FUSD.Vault
		leases.buyAddon(name: name, addon: addon, vault: <- vault)
	}
}

