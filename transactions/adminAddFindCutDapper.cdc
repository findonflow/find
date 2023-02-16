import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

transaction(tenant: Address, merchAddress: Address, findCut: UFix64){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

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

