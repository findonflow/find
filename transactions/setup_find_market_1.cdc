import FindMarketTenant from "../contracts/FindMarketTenant.cdc"


//Transaction that is signed by find to create a find market tenant for find
transaction() {
	prepare(account: AuthAccount) {
		//in finds case the 
		account.save(<- FindMarketTenant.createTenantClient(), to:FindMarketTenant.TenantClientStoragePath)
		account.link<&{FindMarketTenant.TenantClientPublic}>(FindMarketTenant.TenantClientPublicPath, target: FindMarketTenant.TenantClientStoragePath)
	}
}
