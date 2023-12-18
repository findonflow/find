import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

//signed by admin to link tenantClient to a new tenant
transaction(tenant: String, tenantAddress: Address, findCut: UFix64) {
	//versus account
	prepare(account: auth(BorrowValue) &Account) {
		let adminClient=account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath)!

		// pass in the default cut rules here
		let rules = [
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
			rules : rules,
			status: "active",
		)

		//We create a tenant that has both auctions and direct offers
		let tenantCap= adminClient.createFindMarket(name: tenant, address: tenantAddress, findCutSaleItem: saleItem)

		let tenantAccount=getAccount(tenantAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

