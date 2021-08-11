import FIN from "../contracts/FIN.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(from: Address, tag: String, amount: UFix64) {
	prepare(acct: AuthAccount) {


		let seller=getAccount(from)

		let leases=seller.getCapability<&{FIN.LeaseCollectionPublic}>(FIN.LeasePublicPath).borrow()!

		let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let payVault <- vaultRef.withdraw(amount: amount) as! @FUSD.Vault
		

		let finLeases <- FIN.createEmptyLeaseCollection()
		acct.save(<- finLeases, to: FIN.LeaseStoragePath)
		acct.link<&{FIN.LeaseCollectionPublic}>( FIN.LeasePublicPath, target: FIN.LeaseStoragePath)

		let buyer=acct.getCapability<&{FIN.LeaseCollectionPublic}>(FIN.LeasePublicPath)

		leases.buy(tag: tag, vault: <- payVault, leases: buyer)

	}
}
