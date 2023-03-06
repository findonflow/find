import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"
import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"

transaction(nftName: String, nftType: String, cut: UFix64){
    prepare(account: AuthAccount){

		let defaultRules : [FindMarket.TenantRule] = [
			FindMarket.TenantRule(
				name: "Standard",
				types:[Type<@FlowToken.Vault>(), Type<@FUSD.Vault>()],
				ruleType: "ft",
				allow:true
			),
			FindMarket.TenantRule(
				name: "Escrow",
				types:[Type<@FindLeaseMarketSale.SaleItem>(),
				Type<@FindLeaseMarketAuctionEscrow.SaleItem>(),
				Type<@FindLeaseMarketDirectOfferEscrow.SaleItem>()
				],
				ruleType: "listing",
				allow:true
			)
		]

		defaultRules.append(
			FindMarket.TenantRule(
				name: nftName,
				types:[CompositeType(nftType)!],
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
			name: "Standard".concat(nftName).concat("Escrow"),
			cut: royalty,
			rules: defaultRules,
			status: "active"
		)

        let clientRef = account.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")
        clientRef.setMarketOption(saleItem: saleItem)
    }
}

