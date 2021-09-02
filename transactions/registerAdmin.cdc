

import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(name: String, user: Address) {

	prepare(account: AuthAccount) {

		let userAccount=getAccount(user)
		let profileCap = userAccount.getCapability<&{Profile.Public}>(Profile.publicPath)
		let leaseCollectionCap=userAccount.getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		let wallet=account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		let adminClient=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!

		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let payVault <- vaultRef.withdraw(amount: 5.0) as! @FUSD.Vault

		adminClient.register(name: name, vault: <- payVault, profile: profileCap, leases: leaseCollectionCap)
	}
}

