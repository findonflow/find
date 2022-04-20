
import "../contracts/FindMarket.cdc"

//Transaction that is signed by find to create a find market tenant for find
transaction() {
	prepare(account: AuthAccount) {
		//in finds case the 
		account.save(<- FindMarket.createTenantClient(), to:FindMarket.TenantClientStoragePath)
		account.link<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath, target: FindMarket.TenantClientStoragePath)
	}
}
