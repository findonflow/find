
import Admin from "../contracts/Admin.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"

//set up the adminClient in the contract that will own the network
transaction() {

	prepare(account: AuthAccount) {

		if account.getCapability(Admin.AdminProxyPublicPath).check<&AnyResource>() {
			account.unlink(Admin.AdminProxyPublicPath)
			destroy <- account.load<@AnyResource>(from: Admin.AdminProxyStoragePath)
		}
		account.save(<- Admin.createAdminProxyClient(), to:Admin.AdminProxyStoragePath)
		account.link<&{Admin.AdminProxyClient}>(Admin.AdminProxyPublicPath, target: Admin.AdminProxyStoragePath)

		if account.getCapability(FindMarketAdmin.AdminProxyPublicPath).check<&AnyResource>() {
			account.unlink(FindMarketAdmin.AdminProxyPublicPath)
			destroy <- account.load<@AnyResource>(from: FindMarketAdmin.AdminProxyStoragePath)
		}
		account.save(<- FindMarketAdmin.createAdminProxyClient(), to:FindMarketAdmin.AdminProxyStoragePath)
		account.link<&{FindMarketAdmin.AdminProxyClient}>(FindMarketAdmin.AdminProxyPublicPath, target: FindMarketAdmin.AdminProxyStoragePath)
	}
}
