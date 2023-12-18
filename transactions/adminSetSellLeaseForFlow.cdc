import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction(tenant: Address, market: String, merchAddress: Address){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		let tenantRef = adminRef.getTenantRef(tenant)

        var marketType : [Type] = [Type<@FindLeaseMarketSale.SaleItem>()]
		var ftTyp : [Type] = [Type<@FlowToken.Vault>()]

        var rules = [
            FindMarket.TenantRule(name:"FUT", types:[Type<@FlowUtilityToken.Vault>()], ruleType: "ft", allow: true)
            ]
        switch market {
			case "Sale" :
				ftTyp = [Type<@FlowToken.Vault>(), Type<@DapperUtilityCoin.Vault>()]
				let items = tenantRef.getCuts(name:"findFutRoyalty", listingType: Type<@FindLeaseMarketSale.SaleItem>(), nftType:Type<@FIND.Lease>(), ftType:Type<@DapperUtilityCoin.Vault>())
				if items["find"] == nil {
					let cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
					rules = [
						FindMarket.TenantRule(name:"DUC", types:[Type<@DapperUtilityCoin.Vault>()], ruleType: "ft", allow: true)
					]
					adminRef.addFindCut(tenant: tenant, FindCutName: "findFutRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")
				}

            // case "AuctionEscrow" :
            //     marketType = [Type<@FindLeaseMarketAuctionEscrow.SaleItem>()]

            case "AuctionSoft" :
                marketType = [Type<@FindLeaseMarketAuctionSoft.SaleItem>()]
				ftTyp = [Type<@FlowUtilityToken.Vault>()]
				let items = tenantRef.getCuts(name:"findFutRoyalty", listingType: Type<@FindLeaseMarketAuctionSoft.SaleItem>(), nftType:Type<@FIND.Lease>(), ftType:Type<@FlowUtilityToken.Vault>())
				if items["find"] == nil {
					let cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
					adminRef.addFindCut(tenant: tenant, FindCutName: "findFutRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")
				}
            // case "DirectOfferEscrow" :
            //     marketType = [Type<@FindLeaseMarketDirectOfferEscrow.SaleItem>()]

            case "DirectOfferSoft" :
                marketType = [Type<@FindLeaseMarketDirectOfferSoft.SaleItem>()]
				ftTyp = [Type<@FlowUtilityToken.Vault>()]
				let items = tenantRef.getCuts(name:"findFutRoyalty", listingType: Type<@FindLeaseMarketDirectOfferSoft.SaleItem>(), nftType:Type<@FIND.Lease>(), ftType:Type<@FlowUtilityToken.Vault>())
				if items["find"] == nil {
					let cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
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

