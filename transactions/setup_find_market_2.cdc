import "../contracts/Admin.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(tenantAddress: Address) {
	//versus account
	prepare(account: AuthAccount) {
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		//We create a tenant that has both auctions and direct offers
		let tenant <- adminClient.createFindMarketTenant()

		account.save(<- tenant, to:FindMarket.TenantStoragePath)
		account.link<&FindMarket.Tenant>(FindMarket.TenantPrivatePath, target:FindMarket.TenantStoragePath)

		let tenantCap=account.getCapability<&FindMarket.Tenant>(FindMarket.TenantPrivatePath)

		let tenantAccount=getAccount(tenantAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

