import FiNS from "../contracts/FiNS.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(from: Address, tag: String, amount: UFix64) {
	prepare(acct: AuthAccount) {


		let seller=getAccount(from)

		let leases=seller.getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath).borrow()!

		let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let payVault <- vaultRef.withdraw(amount: amount) as! @FUSD.Vault
		

		let finLeases <- FiNS.createEmptyLeaseCollection()
		acct.save(<- finLeases, to: FiNS.LeaseStoragePath)
		acct.link<&{FiNS.LeaseCollectionPublic}>( FiNS.LeasePublicPath, target: FiNS.LeaseStoragePath)

		let buyer=acct.getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)

		leases.buy(tag: tag, vault: <- payVault, leases: buyer)

	}
}
