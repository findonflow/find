

import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"
import Admin from "../contracts/Admin.cdc"
import Profile from "../contracts/Profile.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(names: [String], user: Address) {

	prepare(account: AuthAccount) {

		let userAccount=getAccount(user)
		let profileCap = userAccount.getCapability<&{Profile.Public}>(Profile.publicPath)
		let leaseCollectionCap=userAccount.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		for name in names {
			adminClient.register(name: name,  profile: profileCap, leases: leaseCollectionCap)
		}
	}
}

