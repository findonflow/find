import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"

transaction(nftName: String, nftType: String, cut: UFix64){
    prepare(account: auth(BorrowValue) &Account){

		let defaultRules : [FindMarket.TenantRule] = [
			FindMarket.TenantRule(
				name: "Flow",
				types:[Type<@FlowToken.Vault>(),Type<@FUSD.Vault>(),Type<@FiatToken.Vault>() ],
				ruleType: "ft",
				allow:true
			),
				FindMarket.TenantRule(
				name: "Escrow",
				types:[Type<@FindMarketSale.SaleItem>(), Type<@FindMarketAuctionEscrow.SaleItem>(), Type<@FindMarketDirectOfferEscrow.SaleItem>()],
				ruleType: "listing",
				allow:true
			)
		]

		var royalty : MetadataViews.Royalty? = nil
		if cut != 0.0 {
			royalty = MetadataViews.Royalty(
				receiver: account.getCapability<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath),
				cut: cut,
				description: "tenant"
			)
		}

		let saleItem = FindMarket.TenantSaleItem(
			name: "Flow".concat(nftName).concat("Escrow"),
			cut: royalty,
			rules: defaultRules,
			status: "active"
		)

        let clientRef = account.storage.borrow<&FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")
        clientRef.setMarketOption(saleItem: saleItem)
    }
}

