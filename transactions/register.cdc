import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String) {
	prepare(acct: AuthAccount) {

		let profileCap = acct.getCapability<&{Profile.Public}>(Profile.publicPath)

		let price=FIND.calculateCost(name)
		log("The cost for registering this name is ".concat(price.toString()))

		let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let payVault <- vaultRef.withdraw(amount: price) as! @FUSD.Vault

		let leaseCollectionCap=acct.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollectionCap.check() {
			let finLeases <- FIND.createEmptyLeaseCollection()
			acct.save(<- finLeases, to: FIND.LeaseStoragePath)
			acct.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let leases=acct.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)!
		leases.register(name: name, vault: <- payVault)

	}
}
