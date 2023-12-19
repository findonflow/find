import FindMarketCutStruct from "../contracts/FindMarketCutStruct.cdc"

access(all) contract interface FindMarketCutInterface {

	access(all) let contractName: String
	access(all) let category: String

	pub event Cut(tenant: String, type: String, cutInfo: [FindMarketCutStruct.EventSafeCut], action: String, remark: String?)

	access(account) fun setTenantCuts(tenant: String, types: [Type], cuts: FindMarketCutStruct.Cuts)
	access(account) fun removeTenantCuts(tenant: String, types: [Type]) : [FindMarketCutStruct.Cuts]
	access(account) fun setTenantRulesCache(tenant: String, ruleId: String, result: FindMarketCutStruct.Cuts)
	access(all) getTenantRulesCache(tenant: String, ruleId: String) : FindMarketCutStruct.Cuts?
	access(all) getCut(tenant: String, listingType: Type, nftType: Type, ftType: Type) : FindMarketCutStruct.Cuts?
	access(account) fun resetTenantRulesCache(_ tenant: String)

}
