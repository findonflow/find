import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(tenant: Address) {
	//versus account
	prepare(account: auth(BorrowValue) &Account) {
		let adminClient=account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath)!

		adminClient.removeFindMarketTenant(tenant: tenant)
	}
}

