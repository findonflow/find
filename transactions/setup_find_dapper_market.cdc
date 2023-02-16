import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(adminAddress: Address, tenantAddress: Address, name:String) {
	//versus account
	prepare(account: AuthAccount) {
		let adminClient=account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath)!
		let tenantCap= adminClient.createFindMarket(name: name, address: tenantAddress, defaultCutRules: [], findCut:nil)
		let tenantAccount=getAccount(adminAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

