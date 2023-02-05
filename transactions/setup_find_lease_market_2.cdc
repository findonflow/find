import Admin from "../contracts/Admin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"

transaction(tenantAddress: Address) {
	//versus account
	prepare(account: AuthAccount) {
		// pass in the default cut rules here
		let cut = [
			FindMarket.TenantRule( name:"standard ft", types:[Type<@DapperUtilityCoin.Vault>()], ruleType:"ft", allow:true)
		]

		let royalty = MetadataViews.Royalty(
			receiver: account.getCapability<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath),
			cut: 0.025,
			description: "find"
		)

		let saleItem = FindMarket.TenantSaleItem(
			name: "FindRoyalty",
			cut: royalty,
			rules : cut,
			status: "active",
		)

		//We create a tenant that has both auctions and direct offers
		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		let tenantCap= adminClient.createFindMarket(name: "findLease", address: tenantAddress, findCutSaleItem: saleItem)

		let tenantAccount=getAccount(tenantAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

