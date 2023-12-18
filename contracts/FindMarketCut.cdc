import FindMarketCutStruct from "../contracts/FindMarketCutStruct.cdc"
import FindMarketCutInterface from "../contracts/FindMarketCutInterface.cdc"
import FindUtils from "../contracts/FindUtils.cdc"

pub contract FindMarketCut {

	pub let categoryToContractName: {String : String}

	pub event Cut(tenant: String, type: String, category: String, contractName: String, cutInfo: [FindMarketCutStruct.EventSafeCut], action: String, remark: String?)

	access(all) getRuleId(listingType: Type, nftType:Type, ftType:Type) : String {
		let s : [String] = [listingType.identifier, nftType.identifier, ftType.identifier]
		return FindUtils.joinString(s, sep: "-")
	}

	access(all) getCuts(tenant: String, listingType: Type, nftType:Type, ftType:Type): {String : FindMarketCutStruct.Cuts} {
		let res : {String : FindMarketCutStruct.Cuts} = {}
		for category in self.categoryToContractName.keys {
			let contractName = self.categoryToContractName[category]!
			let con = self.borrowContract(contractName)
			if let cut = con.getCut(tenant: tenant, listingType: listingType, nftType: nftType, ftType: ftType) {
				res[category] = cut
			}
		}
		return res
	}

	// Helper functions for setting up cuts
	access(contract) fun borrowContract(_ contractName: String) : &FindMarketCutInterface {
		var identifier = contractName
		if let category = self.categoryToContractName[contractName] {
			identifier = category
		}
		return self.account.contracts.borrow<&FindMarketCutInterface>(name: identifier) ?? panic("Cannor borrow contract with identifier : ".concat(identifier))
	}

	access(account) fun setTenantCuts(tenant: String, types: [Type], category: String, cuts: FindMarketCutStruct.Cuts) {
		let contractName = self.categoryToContractName[category] ?? panic("Category is not set to link with contract. Category ".concat(category))
		let con = self.borrowContract(contractName)
		con.setTenantCuts(tenant: tenant, types: types, cuts: cuts)
		let cutInfo = cuts.getEventSafeCuts()
		for t in types {
			emit Cut(tenant: tenant, type: t.identifier, category: category, contractName: contractName, cutInfo: cutInfo, action: "add", remark: nil)
		}
	}

	access(account) fun removeTenantCuts(tenant: String, types: [Type], category: String) {
		let contractName = self.categoryToContractName[category] ?? panic("Category is not set to link with contract. Category ".concat(category))
		let con = self.borrowContract(contractName)
		let cuts = con.removeTenantCuts(tenant: tenant, types: types)
		for i, t in types {
			let cutInfo = cuts[i].getEventSafeCuts()
			emit Cut(tenant: tenant, type: t.identifier, category: category, contractName: contractName, cutInfo: cutInfo, action: "remove", remark: nil)
		}
	}

	access(account) fun setTenantRulesCache(tenant: String, ruleId: String, category: String, result: FindMarketCutStruct.Cuts) {
		let contractName = self.categoryToContractName[category] ?? panic("Category is not set to link with contract. Category ".concat(category))
		let con = self.borrowContract(contractName)
		con.setTenantRulesCache(tenant: tenant, ruleId: ruleId, result: result)
	}

	access(all) getTenantRules(tenant: String, ruleId: String, category: String) : FindMarketCutStruct.Cuts? {
		let contractName = self.categoryToContractName[category] ?? panic("Category is not set to link with contract. Category ".concat(category))
		let con = self.borrowContract(contractName)
		let res = con.getTenantRulesCache(tenant: tenant, ruleId: ruleId)
		return res
	}

	access(account) fun resetTenantRulesCache(tenant: String, category: String) {
		let contractName = self.categoryToContractName[category] ?? panic("Category is not set to link with contract. Category ".concat(category))
		let con = self.borrowContract(contractName)
		con.resetTenantRulesCache(tenant)
	}

	access(account) fun setCategory(category: String, contractName: String) {
		self.categoryToContractName[category] = contractName
	}

	access(account) fun removeCategory(category: String) {
		self.categoryToContractName.remove(key: category) ?? panic("Category is not set to link with contract. Category ".concat(category))
	}

	init(){
		self.categoryToContractName = {}
	}

}
