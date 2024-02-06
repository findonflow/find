import "FindMarket"
import "FlowToken"
import "FUSD"
import "FiatToken"
import "FindMarketSale"
import "DapperUtilityCoin"
import "FlowUtilityToken"
import "FindMarketAuctionEscrow"
import "FindMarketDirectOfferEscrow"
import "MetadataViews"
import "FungibleToken"
import "FungibleTokenSwitchboard"

transaction(nftName: String, nftTypes: [String], cut: UFix64){
    prepare(account: auth(BorrowValue) &Account){

        let nfts : [Type] = []
        for t in nftTypes {
            nfts.append(CompositeType(t)!)
        }

        let defaultRules : [FindMarket.TenantRule] = [
        FindMarket.TenantRule(
            name: "Standard",
            types:[
            Type<@DapperUtilityCoin.Vault>(), 
            Type<@FlowUtilityToken.Vault>(),
            Type<@FlowToken.Vault>()
            ],
            ruleType: "ft",
            allow:true
        ),
        FindMarket.TenantRule(
            name: nftName,
            types:nfts,
            ruleType: "nft",
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
                receiver: account.capabilities.get<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.ReceiverPublicPath)!,
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

        let clientRef = account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: FindMarket.TenantClientStoragePath) ?? panic("Cannot borrow Tenant Client Reference.")
        clientRef.setMarketOption(saleItem: saleItem)
    }
}

