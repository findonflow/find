import "FindMarket"


//Transaction that is signed by find to create a find market tenant for find
transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		//in finds case the
		destroy account.load<@FindMarket.TenantClient>(from:FindMarket.TenantClientStoragePath)
		account.unlink(FindMarket.TenantClientPublicPath)
	}
}
