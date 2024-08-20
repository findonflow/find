import "FungibleToken"
import "MetadataViews"
import "DapperUtilityCoin"
import "FlowUtilityToken"
import "FindMarket"
import "FlowToken"
import "FIND"
import "FindMarketSale"
import "FindMarketAuctionSoft"
import "FindMarketDirectOfferSoft"

transaction(market: String, merchAddress: Address, tenantCut: UFix64){
    prepare(account: auth(BorrowValue) &Account){
        let clientRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")

		// emulator
		var identifier = "A.f8d6e0586b0a20c7.Wearables.NFT"
		if merchAddress== 0x55459409d30274ee {
		// This is for mainnet
			identifier = "A.e81193c424cfd3fb.Wearables.NFT"
		} else if merchAddress == 0x4748780c8bf65e19 {
		// This is for testnet
			identifier = "A.1e0493ee604e7598.Wearables.NFT"
		}

        var marketType : [Type] = [Type<@FindMarketSale.SaleItem>()]
		var ftTyp : [Type] = [
			Type<@FlowUtilityToken.Vault>()
			// Type<@DapperUtilityCoin.Vault>()
			]
		var nftTyp: [Type] = [
			CompositeType(identifier)!
		]

        switch market {
            case "AuctionEscrow" :
                marketType = [Type<@FindLeaseMarketAuctionEscrow.SaleItem>()]

            case "AuctionSoft" :
                marketType = [Type<@FindMarketAuctionSoft.SaleItem>()]

            case "DirectOfferEscrow" :
                marketType = [Type<@FindLeaseMarketDirectOfferEscrow.SaleItem>()]

            case "DirectOfferSoft" :
                marketType = [Type<@FindMarketDirectOfferSoft.SaleItem>()]
        }

		let cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		let r = MetadataViews.Royalty(receiver: cap, cut: tenantCut, description: "dapper")

		let rules = [
            FindMarket.TenantRule(name:"DapperFUT", types:ftTyp, ruleType: "ft", allow: true),
            FindMarket.TenantRule(name: "Wearables", types:nftTyp, ruleType: "nft", allow: true),
            FindMarket.TenantRule(name: market, types:marketType, ruleType: "listing", allow: true)
            ]

        clientRef.setMarketOption(name: "DapperFUTWearables".concat(market), cut: r, rules: rules)
    }
}

