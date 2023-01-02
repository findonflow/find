import Admin from "../contracts/Admin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

transaction(tenant: Address, cut: UFix64?){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
		// pass in the default cut rules here
		let rules = [
			FindMarket.TenantRule( name:"standard ft", types:[Type<@FlowUtilityToken.Vault>()], ruleType:"ft", allow:true) 
		]
        adminRef.setFindCut(tenant: tenant, saleItemName:"findRoyalty", cut: cut, rules: rules, status: "active")
    }
}

