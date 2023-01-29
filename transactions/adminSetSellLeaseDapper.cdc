import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction(market: String, merchAddress: Address){
    prepare(account: AuthAccount){
        let clientRef = account.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")

        var marketType : [Type] = [Type<@FindLeaseMarketSale.SaleItem>()]
		var ftTyp : [Type] = [
			// Type<@FlowUtilityToken.Vault>(),
			Type<@DapperUtilityCoin.Vault>()
			]

        switch market {
            // case "AuctionEscrow" :
            //     marketType = [Type<@FindLeaseMarketAuctionEscrow.SaleItem>()]

            case "AuctionSoft" :
                marketType = [Type<@FindLeaseMarketAuctionSoft.SaleItem>()]

            // case "DirectOfferEscrow" :
            //     marketType = [Type<@FindLeaseMarketDirectOfferEscrow.SaleItem>()]

            case "DirectOfferSoft" :
                marketType = [Type<@FindLeaseMarketDirectOfferSoft.SaleItem>()]
        }

		let cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		let r = MetadataViews.Royalty(receiver: cap, cut: 0.06, description: "find")

		let rules = [
			FindMarket.TenantRule(name:"DapperDUC", types:ftTyp, ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Lease", types:[Type<@FIND.Lease>()], ruleType: "nft", allow: true),
            FindMarket.TenantRule(name: market, types:marketType, ruleType: "listing", allow: true)
            ]

        clientRef.setMarketOption(name: "DapperDUCLease".concat(market), cut: r, rules: rules)
    }
}

