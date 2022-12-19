import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Admin from "../contracts/Admin.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction(tenant: Address, market: String){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		let tenantRef = adminRef.getTenantRef(tenant) 

        var marketType : [Type] = [Type<@FindLeaseMarketSale.SaleItem>()]
		var ftTyp : [Type] = [Type<@FlowToken.Vault>()]

        let rules = [
            FindMarket.TenantRule(name:"FUT", types:[Type<@FlowUtilityToken.Vault>()], ruleType: "ft", allow: true)
            ]
        switch market {
			case "Sale" : 
				ftTyp = [Type<@FlowToken.Vault>(), Type<@FlowUtilityToken.Vault>()]
				let items = tenantRef.getTenantCut(name:"findFutRoyalty", listingType: Type<@FindLeaseMarketAuctionSoft.SaleItem>(), nftType:Type<@FIND.Lease>(), ftType:Type<@FlowUtilityToken.Vault>())
				if items.findCut == nil {
					let cap = getAccount(account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
					adminRef.addFindCut(tenant: tenant, FindCutName: "findFutRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")
				}

            // case "AuctionEscrow" :
            //     marketType = [Type<@FindLeaseMarketAuctionEscrow.SaleItem>()]

            case "AuctionSoft" :
                marketType = [Type<@FindLeaseMarketAuctionSoft.SaleItem>()]
				ftTyp = [Type<@FlowUtilityToken.Vault>()]
				let items = tenantRef.getTenantCut(name:"findFutRoyalty", listingType: Type<@FindLeaseMarketAuctionSoft.SaleItem>(), nftType:Type<@FIND.Lease>(), ftType:Type<@FlowUtilityToken.Vault>())
				if items.findCut == nil {
					let cap = getAccount(account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
					adminRef.addFindCut(tenant: tenant, FindCutName: "findFutRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")
				}
            // case "DirectOfferEscrow" :
            //     marketType = [Type<@FindLeaseMarketDirectOfferEscrow.SaleItem>()]

            case "DirectOfferSoft" :
                marketType = [Type<@FindLeaseMarketDirectOfferSoft.SaleItem>()]
				ftTyp = [Type<@FlowUtilityToken.Vault>()]
				let items = tenantRef.getTenantCut(name:"findFutRoyalty", listingType: Type<@FindLeaseMarketAuctionSoft.SaleItem>(), nftType:Type<@FIND.Lease>(), ftType:Type<@FlowUtilityToken.Vault>())
				if items.findCut == nil {
					let cap = getAccount(account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
					adminRef.addFindCut(tenant: tenant, FindCutName: "findFutRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")
				}
        }

        let saleItem = FindMarket.TenantSaleItem(name:"FlowLease".concat(market), cut: nil, rules:[
            FindMarket.TenantRule(name:"Flow", types:ftTyp, ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Lease", types:[Type<@FIND.Lease>()], ruleType: "nft", allow: true),
            FindMarket.TenantRule(name: market, types:marketType, ruleType: "listing", allow: true)
            ], 
            status: "active"
        )

        adminRef.setMarketOption(tenant: tenant, saleItem: saleItem)
    }
}

