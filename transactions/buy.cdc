import FIND from "../contracts/FIND.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(from: Address, name: String, amount: UFix64) {
	prepare(acct: AuthAccount) {


		let seller=getAccount(from)

		let leases=seller.getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow()!

		let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let payVault <- vaultRef.withdraw(amount: amount) as! @FUSD.Vault
		

		let finLeases <- FIND.createEmptyLeaseCollection()
		acct.save(<- finLeases, to: FIND.LeaseStoragePath)
		acct.link<&{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)

		let buyer=acct.getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		leases.buy(name: name, vault: <- payVault, leases: buyer)

	}
}
