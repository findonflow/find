import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"

transaction(market: String, merchAddress: Address){
    prepare(account: AuthAccount){
        let clientRef = account.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")

        var marketType : [Type] = [Type<@FindMarketSale.SaleItem>()]
		var ftTyp : [Type] = [
			// Type<@FlowUtilityToken.Vault>()
			Type<@DapperUtilityCoin.Vault>()
			]
		var nftTyp: [Type] = [
			CompositeType("A.1e0493ee604e7598.Wearables.NFT")!
		]

        switch market {
            // case "AuctionEscrow" :
            //     marketType = [Type<@FindLeaseMarketAuctionEscrow.SaleItem>()]

            case "AuctionSoft" :
                marketType = [Type<@FindMarketAuctionSoft.SaleItem>()]

            // case "DirectOfferEscrow" :
            //     marketType = [Type<@FindLeaseMarketDirectOfferEscrow.SaleItem>()]

            case "DirectOfferSoft" :
                marketType = [Type<@FindMarketDirectOfferSoft.SaleItem>()]
        }

		let cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		let r = MetadataViews.Royalty(receiver: cap, cut: 0.06, description: "find")

		let rules = [
            FindMarket.TenantRule(name:"DapperDUC", types:ftTyp, ruleType: "ft", allow: true),
            FindMarket.TenantRule(name: "Wearables", types:nftTyp, ruleType: "nft", allow: true),
            FindMarket.TenantRule(name: market, types:marketType, ruleType: "listing", allow: true)
            ]

        clientRef.setMarketOption(name: "DapperDUCWearables".concat(market), cut: r, rules: rules)
    }
}

