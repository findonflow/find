import "FindMarketCutInterface"
import "FindMarketCutStruct"
import "FindMarketCut"

access(all) contract FindMarketInfrastructureCut : FindMarketCutInterface {

    access(all) let contractName: String
    access(all) let category: String

    // tenant to {ruleId to cut}
    access(contract) let cuts : {String : {String : FindMarketCutStruct.Cuts}}
    access(contract) let cutsCache : {String : {String : FindMarketCutStruct.Cuts}}

    access(all) event Cut(tenant: String, type: String, cutInfo: [FindMarketCutStruct.EventSafeCut], action: String, remark: String?)

    access(all) fun getCut(tenant: String, listingType: Type, nftType: Type, ftType: Type) : FindMarketCutStruct.Cuts? {

        let ruleId = FindMarketCut.getRuleId(listingType: listingType, nftType: nftType, ftType: ftType)
        if let cache = self.getTenantRulesCache(tenant: tenant, ruleId: ruleId) {
            return cache
        }

        let types = [listingType.identifier, nftType.identifier, ftType.identifier]
        var cuts : [{FindMarketCutStruct.Cut}] = []
        var returningCut : FindMarketCutStruct.Cuts? = nil
        for t in types {
            let cutMapping = self.cuts[tenant] ?? {}
            if let c = cutMapping[t] {
                cuts.appendAll(c.cuts)
            }
        }
        if cuts.length > 0 {
            returningCut = FindMarketCutStruct.Cuts(cuts:cuts)

            // set cache if not already
            // we do not need to check if cache exist here, because if it is, it will be returned earlier
            self.setTenantRulesCache(tenant: tenant, ruleId: ruleId, result: returningCut!)
        }

        return returningCut
    }

    access(account) fun setTenantCuts(tenant: String, types: [Type], cuts: FindMarketCutStruct.Cuts) {
        let old = self.cuts[tenant] ?? {}
        for t in types {
            old[t.identifier] = cuts
            emit Cut(tenant: tenant, type: t.identifier, cutInfo: cuts.getEventSafeCuts(), action: "add", remark: nil)
        }
        self.cuts[tenant] = old
    }

    access(account) fun removeTenantCuts(tenant: String, types: [Type]) : [FindMarketCutStruct.Cuts] {
        var panicMsg = "tenant infrastructure cut is not registered. Tenant : ".concat(tenant)
        let old = self.cuts[tenant] ?? panic(panicMsg)
        let cutsReturn : [FindMarketCutStruct.Cuts] = []
        for t in types {
            let detailedPanicMsg = panicMsg.concat(" Type : ".concat(t.identifier))
            let cuts = old.remove(key: t.identifier) ?? panic(detailedPanicMsg)
            cutsReturn.append(cuts)
            emit Cut(tenant: tenant, type: t.identifier, cutInfo: cuts.getEventSafeCuts(), action: "remove", remark: nil)
        }
        self.cuts[tenant] = old
        return cutsReturn
    }

    access(account) fun setTenantRulesCache(tenant: String, ruleId: String, result: FindMarketCutStruct.Cuts) {

        let old = self.cutsCache[tenant] ?? {}
        if old[ruleId] != nil {
            panic("There is already a cache for this find rule. RuleId : ".concat(ruleId))
        }
        old[ruleId] = result
        self.cutsCache[tenant] = old
    }

    access(all) fun getTenantRulesCache(tenant: String, ruleId: String) : FindMarketCutStruct.Cuts? {
        if self.cutsCache[tenant] == nil {
            return nil
        }
        return self.cutsCache[tenant]![ruleId]
    }

    access(account) fun resetTenantRulesCache(_ tenant: String) {
        self.cutsCache.remove(key: tenant)
    }


    init() {
        self.cuts = {}
        self.cutsCache = {}

        self.contractName = "FindMarketInfrastructureCut"
        self.category = "infrastructure"
        FindMarketCut.setCategory(category: self.category, contractName: self.contractName)
    }

}
