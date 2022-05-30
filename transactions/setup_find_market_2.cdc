import Admin from "../contracts/Admin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(tenantAddress: Address) {
	//versus account
	prepare(account: AuthAccount) {
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		//We create a tenant that has both auctions and direct offers
		let tenantCap= adminClient.createFindMarket(name: "find", address: tenantAddress)

		let tenantAccount=getAccount(tenantAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

