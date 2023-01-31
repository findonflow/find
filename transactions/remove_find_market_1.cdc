import Admin from "../contracts/Admin.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(tenant: Address) {
	//versus account
	prepare(account: AuthAccount) {
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		adminClient.removeFindMarketTenant(tenant: tenant)
	}
}

