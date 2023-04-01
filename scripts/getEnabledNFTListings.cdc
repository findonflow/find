import FindMarket from "../contracts/FindMarket.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FIND from "../contracts/FIND.cdc"

pub let paging : (([String], Int) : [String]) = fun(_ items : [String], _ page: Int) : [String] {
	let pageSize = 50
	var start = (page - 1) * pageSize
	let end = start + pageSize
	if start >= items.length {
		return []
	}
	var res : [String] = []
	var valid = true
	while valid {
		res.append(items[start])
		start = start + 1
		if start >= end || start >= items.length {
			valid = false
		}
	}
	return res
}


pub let removeElement = fun (_ arr: [Type], _ element: Type): [Type] {
			var i = arr.firstIndex(of: element)
			while i != nil {
				arr.remove(at: i!)
				i = arr.firstIndex(of: element)
			}
			return arr
		}


pub fun main(page: Int) : Report? {

	let tenant = FindMarket.getFindTenantAddress()
	let tenantRef = FindMarket.getTenant(tenant)

	var allTypes = NFTCatalog.getCatalogTypeData().keys
	var allMarketTypes = FindMarket.getSaleItemTypes()
	allTypes = paging(allTypes, page)

	let nonDapper : [Item] = []
	let Dapper : [Item] = []

	for t in allTypes {
		for m in allMarketTypes {

			if let l = tenantRef.getAllowedListings(nftType: Type<@FIND.Lease>(), marketType: m) {
				if l.status == "active" {
					let dapperFT : [Type] = []
					var nonDapperFT : [Type] = []
					if l.ftTypes.contains(Type<@DapperUtilityCoin.Vault>()) {
						dapperFT.append(Type<@DapperUtilityCoin.Vault>())
					}
					if l.ftTypes.contains(Type<@FlowUtilityToken.Vault>()) {
						dapperFT.append(Type<@FlowUtilityToken.Vault>())
					}
					nonDapperFT = removeElement(l.ftTypes, Type<@DapperUtilityCoin.Vault>())
					nonDapperFT = removeElement(nonDapperFT, Type<@FlowUtilityToken.Vault>())
					if dapperFT.length > 0 {
						Dapper.append(Item(type: t, listingType: m.identifier, ftType: dapperFT))
					}
					if nonDapperFT.length > 0 {
						nonDapper.append(Item(type: t, listingType: m.identifier, ftType: nonDapperFT))
					}
				}
			}
		}
	}

	return Report(nonDapper: nonDapper, dapper: Dapper)
}

pub struct Report {
	pub let nonDapper : [Item]
	pub let dapper : [Item]

	init(
		nonDapper : [Item],
		dapper : [Item]
	) {
		self.nonDapper = nonDapper
		self.dapper = dapper
	}

}

pub struct Item {
	pub let type: String
	pub let listingType: String
	pub let ftType: [Type]

	init(
		type: String,
		listingType: String,
		ftType: [Type]
	) {
		self.type = type
		self.listingType = listingType
		self.ftType = ftType
	}
}


