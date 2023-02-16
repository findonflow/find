import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction(tenantAddress: Address, merchantAddress:Address) {
	//versus account
	prepare(account: AuthAccount) {
		let adminClient=account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath)!

		// pass in the default cut rules here
		let cut = [
			FindMarket.TenantRule( name:"standard ft", types:[Type<@DapperUtilityCoin.Vault>()], ruleType:"ft", allow:true)
		]

		let receiver=getAccount(merchantAddress).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)

		let findRoyalty=MetadataViews.Royalty(receiver: receiver, cut: 0.025,  description: "find")

		//We create a tenant that has both auctions and direct offers
		let tenantCap= adminClient.createFindMarketDapper(name: "findLease", address: tenantAddress, defaultCutRules: cut, findRoyalty:findRoyalty)

		let tenantAccount=getAccount(tenantAddress)
		let tenantClient=tenantAccount.getCapability<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath).borrow()!
		tenantClient.addCapability(tenantCap)
	}
}

