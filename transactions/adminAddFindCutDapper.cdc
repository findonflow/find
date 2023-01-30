import Admin from "../contracts/Admin.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

transaction(tenant: Address, merchAddress: Address){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		// Set up DUC cut
		var cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		var r = MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find")

		var cut = [
			FindMarket.TenantRule( name:"DUC", types:[Type<@DapperUtilityCoin.Vault>()], ruleType:"ft", allow:true)
		]

        adminRef.addFindCut(tenant: tenant, FindCutName: "DapperDUC", rayalty: r, rules: cut, status: "active")

		// Set up FUT cut
		cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		r = MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find")

		cut = [
			FindMarket.TenantRule( name:"FUT", types:[Type<@FlowUtilityToken.Vault>()], ruleType:"ft", allow:true)
		]

        adminRef.addFindCut(tenant: tenant, FindCutName: "DapperFUT", rayalty: r, rules: cut, status: "active")
    }
}

