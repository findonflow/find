import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction(tenant: Address, market: String){
    prepare(account: auth(BorrowValue)  AuthAccountAccount){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

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

