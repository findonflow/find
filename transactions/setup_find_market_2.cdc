import Admin from "../contracts/Admin.cdc"
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(tenantAddress: Address) {
	//versus account
	prepare(account: AuthAccount) {
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		//We create a tenant that has both auctions and direct offers
		let tenantCap= adminClient.createFindMarketTenant(name: "find", address: tenantAddress)

		let tenantAccount=getAccount(tenantAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarketTenant.TenantClientPublic}>(FindMarketTenant.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

