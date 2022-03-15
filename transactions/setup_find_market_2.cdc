import "../contracts/Admin.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(tenantAddress: Address, auctions:Bool, directOffers:Bool) {
	//versus account
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		//We create a tenant that has both auctions and direct offers
		let tenant <- adminClient.createFindMarketTenant(auctions:auctions, directOffers:directOffers)

		//TODO: these have to be seperate for each market and client we create, based on the paths above!
		//TODO: better to just do this in the admin function?
		account.save(<- tenant, to:FindMarket.TenantStoragePath)
		account.link<&FindMarket.Tenant>(FindMarket.TenantPrivatePath, target:FindMarket.TenantStoragePath)

		let tenantCap=account.getCapability<&FindMarket.Tenant>(FindMarket.TenantPrivatePath)

		let tenantAccount=getAccount(tenantAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarket.TenantPublic}>(FindMarket.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

