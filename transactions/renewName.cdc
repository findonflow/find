import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {
	prepare(acct: AuthAccount) {

		let price=FIND.calculateCost(name)
		if amount != price {
			panic("expected renew cost is not the same as calculated renew cost")
		}
		let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the fusdVault!")
		let payVault <- vaultRef.withdraw(amount: price) as! @FUSD.Vault

		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let finToken= finLeases.borrow(name)
		finToken.extendLease(<- payVault)
	}
}
