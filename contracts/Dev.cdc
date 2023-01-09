import FindMarket from "./FindMarket.cdc"
import FindMarketSale from "./FindMarketSale.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindRulesCache from "./FindRulesCache.cdc"

pub contract Dev {

	pub fun TestRoyaltyChangedPayFunction(addr: Address, nftInfo: FindMarket.NFTInfo) {

		let tenant = "Find"
		let id = UInt64(1)
		let saleItemCol = FindMarketSale.getSaleItemCapability(marketplace:Dev.account.address, user:addr)!.borrow()!
		let saleItem = saleItemCol.borrowSaleItem(saleItemCol.getIds()[0])


		let receiver = Dev.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		let royalties = MetadataViews.Royalties([
			MetadataViews.Royalty(receiver: receiver, cut: 0.01, description: "test")
		])

		let cuts : FindRulesCache.TenantCuts = FindRulesCache.TenantCuts(findCut: nil, tenantCut: nil)

		let function =
			fun(_ addr: Address) : String? {
				return nil
			}
		let vault <- Dev.account.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)!.withdraw(amount: saleItem.getBalance())

		let resolvedAddress : {Address : String} = {}

		FindMarket.pay(tenant: tenant, id: id, saleItem: saleItem, vault: <- vault, royalty: royalties, nftInfo:nftInfo, cuts:cuts, resolver: function, resolvedAddress: resolvedAddress)
	}

}
