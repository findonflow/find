import "FindMarketAdmin"
import "FindMarket"
import "FlowToken"
import "FUSD"
import "FiatToken"
import "DapperUtilityCoin"
import "FlowUtilityToken"
import "MetadataViews"

//signed by admin to link tenantClient to a new tenant
transaction(tenant: String, adminAddress: Address, tenantAddress: Address, findCut: UFix64) {
	//versus account
	prepare(account: auth(BorrowValue) &Account) {
		let adminClient=account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath)!

		// pass in the default cut rules here
		let cut = [
			FindMarket.TenantRule( name:"standard ft", types:[Type<@FUSD.Vault>(), Type<@FlowToken.Vault>(), Type<@FiatToken.Vault>(), Type<@DapperUtilityCoin.Vault>() , Type<@FlowUtilityToken.Vault>()], ruleType:"ft", allow:true)
		]

		let royalty = MetadataViews.Royalty(
			receiver: adminClient.getSwitchboardReceiverPublic(),
			cut: findCut,
			description: "find"
		)

		let saleItem = FindMarket.TenantSaleItem(
			name: "findRoyalty",
			cut: royalty,
			rules : cut,
			status: "active",
		)

		//We create a tenant that has both auctions and direct offers
		let tenantCap= adminClient.createFindMarket(name: tenant, address: tenantAddress, findCutSaleItem: saleItem)

		let tenantAccount=getAccount(adminAddress)
		let tenantClient=tenantAccount.capabilities.get<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath)!.borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

