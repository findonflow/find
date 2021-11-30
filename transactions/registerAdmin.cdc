

import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"
import Admin from "../contracts/Admin.cdc"
import Profile from "../contracts/Profile.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(name: String, user: Address) {

	prepare(account: AuthAccount) {

		let userAccount=getAccount(user)
		let profileCap = userAccount.getCapability<&{Profile.Public}>(Profile.publicPath)
		let leaseCollectionCap=userAccount.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		let wallet=account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the fusdVault!")

		let cost = FIND.calculateCost(name)
		let payVault <- vaultRef.withdraw(amount: cost) as! @FUSD.Vault

		adminClient.register(name: name, vault: <- payVault, profile: profileCap, leases: leaseCollectionCap)
	}
}

