import FindMarket from "../contracts/FindMarket.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"

transaction(nftName: String, nftTypes: [String], cut: UFix64){
    prepare(account: AuthAccount){

		let defaultRules : [FindMarket.TenantRule] = [
			FindMarket.TenantRule(
				name: "Dapper",
				types:[
					Type<@FlowUtilityToken.Vault>(),
					Type<@DapperUtilityCoin.Vault>()
				],
				ruleType: "ft",
				allow:true
			),
			FindMarket.TenantRule(
				name: "Soft",
				types:[
					Type<@FindMarketSale.SaleItem>(),
					Type<@FindMarketAuctionSoft.SaleItem>(),
					Type<@FindMarketDirectOfferSoft.SaleItem>()
				],
				ruleType: "listing",
				allow:true
			)
		]

		let nfts : [Type] = []
		for t in nftTypes {
			nfts.append(CompositeType(t)!)
		}

		defaultRules.append(
			FindMarket.TenantRule(
				name: nftName,
				types:nfts,
				ruleType: "nft",
				allow:true
			)
		)

		var royalty : MetadataViews.Royalty? = nil
		if cut != 0.0 {
			royalty = MetadataViews.Royalty(
				receiver: account.getCapability<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath),
				cut: cut,
				description: "tenant"
			)
		}

		let saleItem = FindMarket.TenantSaleItem(
			name: "Dapper".concat(nftName).concat("Soft"),
			cut: royalty,
			rules: defaultRules,
			status: "active"
		)

        let clientRef = account.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")
        clientRef.setMarketOption(saleItem: saleItem)
    }
}

