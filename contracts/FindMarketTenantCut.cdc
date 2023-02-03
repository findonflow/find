import FindMarketCutInterface from "../contracts/FindMarketCutInterface.cdc"
import FindMarketCutStruct from "../contracts/FindMarketCutStruct.cdc"
import FindMarketCut from "../contracts/FindMarketCut.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

pub contract FindMarketTenantCut : FindMarketCutInterface {

	pub let contractName: String
	pub let category: String

	// tenant to {ruleId to cut}
	access(contract) let cutsCache : {String : {String : FindMarketCutStruct.Cuts}}

	pub event Cut(tenant: String, type: String, cutInfo: [FindMarketCutStruct.EventSafeCut], action: String, remark: String?)

	pub fun getCut(tenant: String, listingType: Type, nftType: Type, ftType: Type) : FindMarketCutStruct.Cuts? {

		let ruleId = FindMarketCut.getRuleId(listingType: listingType, nftType: nftType, ftType: ftType)
		if let cache = self.getTenantRulesCache(tenant: tenant, ruleId: ruleId) {
			return cache
		}

		let tenantRef = self.getTenant(tenant)
		let cuts = tenantRef.getTenantCut(name: "", listingType: listingType, nftType:nftType, ftType:ftType)

		if cuts != nil {
			// set cache if not already
			// we do not need to check if cache exist here, because if it is, it will be returned earlier
			self.setTenantRulesCache(tenant: tenant, ruleId: ruleId, result: cuts!)
		}

		return cuts
	}

	// not used, just here to adhere to interface
	access(account) fun setTenantCuts(tenant: String, types: [Type], cuts: FindMarketCutStruct.Cuts) {
		panic("Function not used. setTenantCuts")
	}

	// not used, just here to adhere to interface
	access(account) fun removeTenantCuts(tenant: String, types: [Type]) : [FindMarketCutStruct.Cuts] {
		panic("Function not used. removeTenantCuts")
	}

	access(account) fun setTenantRulesCache(tenant: String, ruleId: String, result: FindMarketCutStruct.Cuts) {
		let old = self.cutsCache[tenant] ?? {}
		if old[ruleId] != nil {
			panic("There is already a cache for this find rule. RuleId : ".concat(ruleId))
		}
		old[ruleId] = result
		self.cutsCache[tenant] = old
	}

	pub fun getTenantRulesCache(tenant: String, ruleId: String) : FindMarketCutStruct.Cuts? {
		if self.cutsCache[tenant] == nil {
			return nil
		}
		return self.cutsCache[tenant]![ruleId]
	}

	access(account) fun resetTenantRulesCache(_ tenant: String) {
		self.cutsCache.remove(key: tenant)
	}

	access(contract) fun getTenant(_ tenant: String) : &FindMarket.Tenant {
		let pid = FindMarket.getTenantPathForName(tenant)
		let storagePath = StoragePath(identifier: pid)!

		return FindMarketTenantCut.account.borrow<&FindMarket.Tenant>(from: storagePath) ?? panic("Cannot borrow Tenant : ".concat(tenant))
	}


	init() {
		self.cutsCache = {}
		self.contractName = "FindMarketTenantCut"
		self.category = "tenant"

		FindMarketCut.setCategory(category: self.category, contractName: self.contractName)
	}

}
