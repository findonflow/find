import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
transaction(user: String, id: UInt64, amount: UFix64) {

    var targetCapability : Capability<&{NonFungibleToken.Receiver}>
    let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}

    //TODO: should we use concrete implementation here or not?
    let saleItemsCap: Capability<&{FindMarketSale.SaleItemCollectionPublic}>


    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let tenantCapability= FindMarket.getTenantCapability(marketplace)!
        let saleItemType= Type<@FindMarketSale.SaleItemCollection>()

        let tenant = tenantCapability.borrow()!
        let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
        let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

        let saleItemCap= account.capabilities.get<&{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath)
        if saleItemCap==nil {
            account.storage.save(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
            let cap = account.capabilities.storage.issue<&{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(storagePath)
            account.capabilities.publish(cap, at: publicPath)
        }

        let resolveAddress = FIND.resolve(user)
        if resolveAddress == nil {
            panic("The address input is not a valid name nor address. Input : ".concat(user))
        }
        let address = resolveAddress!
        self.saleItemsCap= FindMarketSale.getSaleItemCapability(marketplace: marketplace, user:address) ?? panic("cannot find sale item cap")
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItem>())

        let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)

        let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: item.getItemType().identifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(item.getItemType().identifier))
        let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData

        let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

        //TODO: maybe just use AnyResource here and cast to what we want?
        //

        let col= account.storage.borrow<&AnyResource>(from: nft.storagePath) as? &{NonFungibleToken.Collection}?
        if col == nil {
            let cd = item.getNFTCollectionData()
            account.storage.save(<- cd.createEmptyCollection(), to: cd.storagePath)
            account.capabilities.unpublish(cd.publicPath)
            let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
            account.capabilities.publish(cap, at: cd.publicPath)
            self.targetCapability=cap
        } else {
            //TODO: I do not think this works as intended
            //var targetCapability= account.capabilities.get<&AnyResource>(nft.publicPath) as? Capability<&{NonFungibleToken.Collection}>
            //this works
            var targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath)
            if targetCapability == nil || !targetCapability!.check() {
                let cd = item.getNFTCollectionData()
                let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
                account.capabilities.unpublish(cd.publicPath)
                account.capabilities.publish(cap, at: cd.publicPath)
                targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath)
            }
            self.targetCapability=targetCapability!
        }

        self.walletReference = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
    }

    pre {
        self.walletReference.getBalance() > amount : "Your wallet does not have enough funds to pay for this item"
    }

    execute {
        let vault <- self.walletReference.withdraw(amount: amount)
        self.saleItemsCap.borrow()!.buy(id:id, vault: <- vault, nftCap: self.targetCapability)
    }
}
