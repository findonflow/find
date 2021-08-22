import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"
import FiNS from "../contracts/FiNS.cdc"


transaction(tag: String) {
	prepare(acct: AuthAccount) {

		let profileCap = acct.getCapability<&{Profile.Public}>(Profile.publicPath)

		let price=FiNS.calculateCost(tag)
		log("The cost for registering this tag is ".concat(price.toString()))

		let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let payVault <- vaultRef.withdraw(amount: price) as! @FUSD.Vault

		let leaseCollectionCap=acct.getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)
		if !leaseCollectionCap.check() {
			let finLeases <- FiNS.createEmptyLeaseCollection()
			acct.save(<- finLeases, to: FiNS.LeaseStoragePath)
			acct.link<&{FiNS.LeaseCollectionPublic}>( FiNS.LeasePublicPath, target: FiNS.LeaseStoragePath)
		}

		let leases=acct.borrow<&FiNS.LeaseCollection>(from: FiNS.LeaseStoragePath)!
		leases.register(tag: tag, vault: <- payVault)

	}
}
