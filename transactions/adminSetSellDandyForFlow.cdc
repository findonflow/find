import "FindMarket"
import "FindMarketAdmin"
import "FlowToken"
import "Dandy"
import "FindMarketSale"
import "FindMarketAuctionEscrow"
import "FindMarketAuctionSoft"
import "FindMarketDirectOfferEscrow"
import "FindMarketDirectOfferSoft"
import "FlowUtilityToken"
import "FungibleToken"
import "MetadataViews"

transaction(tenant: Address, market: String){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		let tenantRef = adminRef.getTenantRef(tenant)

        var marketType : [Type] = [Type<@FindMarketSale.SaleItem>()]
		var ftTyp : [Type] = [Type<@FlowToken.Vault>()]

        let rules = [
            FindMarket.TenantRule(name:"FUT", types:[Type<@FlowUtilityToken.Vault>()], ruleType: "ft", allow: true)
            ]

        switch market {
			case "Sale" :
				ftTyp = [Type<@FlowToken.Vault>(), Type<@FlowUtilityToken.Vault>()]
				let items = tenantRef.getCuts(name:"findFutRoyalty", listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType:Type<@Dandy.NFT>(), ftType:Type<@FlowUtilityToken.Vault>())
				if items["find"] == nil {
					let cap = getAccount(account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
					adminRef.addFindCut(tenant: tenant, FindCutName: "findFutRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")
				}

            case "AuctionEscrow" :
                marketType = [Type<@FindMarketAuctionEscrow.SaleItem>()]

            case "AuctionSoft" :
                marketType = [Type<@FindMarketAuctionSoft.SaleItem>()]
				ftTyp = [Type<@FlowUtilityToken.Vault>()]
				let items = tenantRef.getCuts(name:"findFutRoyalty", listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType:Type<@Dandy.NFT>(), ftType:Type<@FlowUtilityToken.Vault>())
				if items["find"] == nil {
					let cap = getAccount(account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
					adminRef.addFindCut(tenant: tenant, FindCutName: "findFutRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")
				}

            case "DirectOfferEscrow" :
                marketType = [Type<@FindMarketDirectOfferEscrow.SaleItem>()]

            case "DirectOfferSoft" :
                marketType = [Type<@FindMarketDirectOfferSoft.SaleItem>()]
				ftTyp = [Type<@FlowUtilityToken.Vault>()]
				let items = tenantRef.getCuts(name:"findFutRoyalty", listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType:Type<@Dandy.NFT>(), ftType:Type<@FlowUtilityToken.Vault>())
				if items["find"] == nil {
					let cap = getAccount(account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
					adminRef.addFindCut(tenant: tenant, FindCutName: "findFutRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")
				}
        }

        let saleItem = FindMarket.TenantSaleItem(name:"FlowDandy".concat(market), cut: nil, rules:[
            FindMarket.TenantRule(name:"Flow", types:ftTyp, ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Dandy", types:[Type<@Dandy.NFT>()], ruleType: "nft", allow: true),
            FindMarket.TenantRule(name: market, types:marketType, ruleType: "listing", allow: true)
            ],
            status: "active"
        )

        adminRef.setMarketOption(tenant: tenant, saleItem: saleItem)
    }
}

