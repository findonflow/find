import FindMarketCutInterface from "../contracts/FindMarketCutInterface.cdc"
import FindMarketCutStruct from "../contracts/FindMarketCutStruct.cdc"
import FindMarketCut from "../contracts/FindMarketCut.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

pub contract FindMarketFindCut : FindMarketCutInterface {

	// tenant to {ruleId to cut}
	access(contract) let cutsCache : {String : {String : FindMarketCutStruct.Cuts}}

	pub event Cut(tenant: String, type: String, cutInfo: [FindMarketCutStruct.EventSafeCut], action: String, remark: String?)

	pub fun getCut(tenant: String, listingType: Type, nftType: Type, ftType: Type) : FindMarketCutStruct.Cuts? {

		let ruleId = FindMarketCut.getRuleId(listingType: listingType, nftType: nftType, ftType: ftType)
		if let cache = self.getTenantRulesCache(tenant: tenant, ruleId: ruleId) {
			return cache
		}

		let pid = FindMarket.getTenantPathForName(tenant)
		let storagePath = StoragePath(identifier: pid)!

		let tenantRef = FindMarketFindCut.account.borrow<&FindMarket.Tenant>(from: storagePath) ?? panic("Cannot borrow Tenant : ".concat(tenant))
		let cuts = tenantRef.getFindCut(name: "", listingType: listingType, nftType:nftType, ftType:ftType)

		if cuts != nil {
			// set cache if not already
			// we do not need to check if cache exist here, because if it is, it will be returned earlier
			self.setTenantRulesCache(tenant: tenant, ruleId: ruleId, result: cuts!)
		}

		return cuts
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


	init() {
		self.cutsCache = {}
	}

}
