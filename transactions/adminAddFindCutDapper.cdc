import "FindMarketAdmin"
import "FungibleToken"
import "MetadataViews"
import "FindMarket"
import "DapperUtilityCoin"
import "FlowUtilityToken"

transaction(tenant: Address, merchAddress: Address, findCut: UFix64){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		// Set up DUC cut
		var cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		var r = MetadataViews.Royalty(receiver: cap, cut: findCut, description: "find")

		var cut = [
			FindMarket.TenantRule( name:"DUC", types:[Type<@DapperUtilityCoin.Vault>()], ruleType:"ft", allow:true)
		]

        adminRef.addFindCut(tenant: tenant, FindCutName: "DapperDUC", rayalty: r, rules: cut, status: "active")

		// Set up FUT cut
		cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		r = MetadataViews.Royalty(receiver: cap, cut: findCut, description: "find")

		cut = [
			FindMarket.TenantRule( name:"FUT", types:[Type<@FlowUtilityToken.Vault>()], ruleType:"ft", allow:true)
		]

        adminRef.addFindCut(tenant: tenant, FindCutName: "DapperFUT", rayalty: r, rules: cut, status: "active")
    }
}

