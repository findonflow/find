import Admin from "../contracts/Admin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(tenantAddress: Address) {
	//versus account
	prepare(account: AuthAccount) {
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		// pass in the default cut rules here
		let cut = [
			FindMarket.TenantRule( name:"standard ft", types:[Type<@FUSD.Vault>(), Type<@FlowToken.Vault>()], ruleType:"ft", allow:true) 
		]
		
		//We create a tenant that has both auctions and direct offers
		let tenantCap= adminClient.createFindMarket(name: "findLease", address: tenantAddress, defaultCutRules: cut)

		let tenantAccount=getAccount(tenantAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

