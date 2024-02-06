import "FindMarketAdmin"
import "FindMarket"
import "FlowUtilityToken"

transaction(tenant: Address, cut: UFix64?){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
		// pass in the default cut rules here
		let rules = [
			FindMarket.TenantRule( name:"standard ft", types:[Type<@FlowUtilityToken.Vault>()], ruleType:"ft", allow:true)
		]
        adminRef.setFindCut(tenant: tenant, saleItemName:"findRoyalty", cut: cut, rules: rules, status: "active")
    }
}

