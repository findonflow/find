import FindForge from "../contracts/FindForge.cdc"


//Transaction that is signed by find to create a find market tenant for find
transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		//in finds case the 
		account.save(<- FindForge.createForgeAdminProxyClient(), to:/storage/findForgeAdminProxy)
		account.link<&{FindForge.ForgeAdminProxyClient}>(/public/findForgeAdminProxy, target: /storage/findForgeAdminProxy)
	}
}
