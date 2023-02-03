import MetadataViews from "../contracts/standard/MetadataViews.cdc"

pub contract FindRulesCache {

	access(contract) let tenantFindRules : {String : {String : ActionResult}}
	access(contract) let tenantTenantRules : {String : {String : ActionResult}}
	access(contract) let tenantCuts : {String : {String : TenantCuts}}

	pub struct ActionResult {
		pub let allowed:Bool
		pub let message:String
		pub let name:String

		init(allowed:Bool, message:String, name:String) {
			self.allowed=allowed
			self.message=message
			self.name =name
		}
	}

	pub struct TenantCuts {
		pub let findCut:MetadataViews.Royalty?
		pub let tenantCut:MetadataViews.Royalty?

		init(findCut:MetadataViews.Royalty?, tenantCut:MetadataViews.Royalty?) {
			self.findCut=findCut
			self.tenantCut=tenantCut
		}
	}

	// Tenant Find Rules
	access(account) fun setTenantFindRulesCache(tenant: String, ruleId: String, result: ActionResult) {
		if self.tenantFindRules[tenant] == nil {
			self.tenantFindRules[tenant] = {}
			self.tenantFindRules[tenant]!.insert(key: ruleId, result)
			return
		}

		if self.tenantFindRules[tenant]![ruleId] == nil {
			self.tenantFindRules[tenant]!.insert(key: ruleId, result)
			return
		}

		panic("There is already a cache for this find rule. RuleId : ".concat(ruleId))
	}

	pub fun getTenantFindRules(tenant: String, ruleId: String) : ActionResult? {
		if self.tenantFindRules[tenant] == nil {
			return nil
		}
		return self.tenantFindRules[tenant]![ruleId]
	}

	access(account) fun resetTenantFindRulesCache(_ tenant: String) {
		self.tenantFindRules.remove(key: tenant)
	}

	// Tenant Tenant Rules
	access(account) fun setTenantTenantRulesCache(tenant: String, ruleId: String, result: ActionResult) {
		if self.tenantTenantRules[tenant] == nil {
			self.tenantTenantRules[tenant] = {}
			self.tenantTenantRules[tenant]!.insert(key: ruleId, result)
			return
		}

		if self.tenantTenantRules[tenant]![ruleId] == nil {
			self.tenantTenantRules[tenant]!.insert(key: ruleId, result)
			return
		}

		panic("There is already a cache for this tenant rule. RuleId : ".concat(ruleId))
	}

	pub fun getTenantTenantRules(tenant: String, ruleId: String) : ActionResult? {
		if self.tenantTenantRules[tenant] == nil {
			return nil
		}
		return self.tenantTenantRules[tenant]![ruleId]
	}

	access(account) fun resetTenantTenantRulesCache(_ tenant: String) {
		self.tenantTenantRules.remove(key: tenant)
	}

	access(account) fun setTenantCutCache(tenant: String, ruleId: String, cut: TenantCuts) {
		if self.tenantCuts[tenant] == nil {
			self.tenantCuts[tenant] = {}
			self.tenantCuts[tenant]!.insert(key: ruleId, cut)
			return
		}

		if self.tenantCuts[tenant]![ruleId] == nil {
			self.tenantCuts[tenant]!.insert(key: ruleId, cut)
			return
		}

		panic("There is already a cache for this tenant cut information. RuleId : ".concat(ruleId))
	}

	pub fun getTenantCut(tenant: String, ruleId: String) : TenantCuts? {
		if self.tenantCuts[tenant] == nil {
			return nil
		}
		return self.tenantCuts[tenant]![ruleId]
	}

	access(account) fun resetTenantCutCache(_ tenant: String) {
		self.tenantCuts.remove(key: tenant)
	}

	init() {
		self.tenantFindRules = {}
		self.tenantTenantRules = {}
		self.tenantCuts = {}
	}

}
