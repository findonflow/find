import "FindMarket"
import "Profile"
import "FindMarketSale"
import "NFTCatalog"
import "NonFungibleToken"
import "MetadataViews"
import "FungibleToken"
import "DapperStorageRent"

//import "TopShot"
import "DapperUtilityCoin"
import "FlowUtilityToken"

//first argument is the address to the merchant that gets the funds
transaction(address: Address, id: UInt64, amount: UFix64) {

    let targetCapability : Capability<&{NonFungibleToken.Receiver}>
    let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}
    let receiver : Address


    //TODO: should we use concrete implementation here or not?
    let saleItemsCap: Capability<&{FindMarketSale.SaleItemCollectionPublic}>

    let balanceBeforeTransfer: UFix64
    prepare(dapper: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account, account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {
        let marketplace = FindMarket.getFindTenantAddress()
        self.receiver=account.address
        let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
        let tenantCapability= FindMarket.getTenantCapability(marketplace)!
        let tenant = tenantCapability.borrow()!
        let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
        let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

        let saleItemCap= account.capabilities.get<&{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath)
        if !saleItemCap.check() {
            account.storage.save(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
            let cap = account.capabilities.storage.issue<&{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(storagePath)
            account.capabilities.publish(cap, at: publicPath)
        }
        self.saleItemsCap= FindMarketSale.getSaleItemCapability(marketplace: marketplace, user:address) ?? panic("cannot find sale item cap")
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())

        //we do some security check to verify that this tenant can do this operation. This will ensure that the onefootball tenant can only sell using DUC and not some other token. But we can change this with transactions later and not have to modify code/transactions
        let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)
        let collectionIdentifier = NFTCatalog.getCollectionsForType(nftTypeIdentifier: item.getItemType().identifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(item.getItemType().identifier))
        let collection = NFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData

        var ftVaultPath : StoragePath? = nil
        switch item.getFtType() {
        case Type<@DapperUtilityCoin.Vault>() :
            ftVaultPath = /storage/dapperUtilityCoinVault

        case Type<@FlowUtilityToken.Vault>() :
            ftVaultPath = /storage/flowUtilityTokenVault

            default :
            panic("This FT is not supported by the Find Market in Dapper Wallet. Type : ".concat(item.getFtType().identifier))
        }


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
            var targetCapability= account.capabilities.get<&AnyResource>(nft.publicPath) as? Capability<&{NonFungibleToken.Collection}>
            if  !targetCapability!.check() {
                let cd = item.getNFTCollectionData()
                let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
                account.capabilities.unpublish(cd.publicPath)
                account.capabilities.publish(cap, at: cd.publicPath)
                targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath)
            }
            self.targetCapability=targetCapability!

        }

        //TODO: handle topshot

        self.walletReference = dapper.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: ftVaultPath!) ?? panic("No suitable wallet linked for this account")
        self.balanceBeforeTransfer = self.walletReference.balance
    }

    pre {
        self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
    }

    execute {
        let vault <- self.walletReference.withdraw(amount: amount)
        self.saleItemsCap.borrow()!.buy(id:id, vault: <- vault, nftCap: self.targetCapability)
        DapperStorageRent.tryRefill(self.receiver)
    }

    // Check that all dapper Coin was routed back to Dapper
    post {
        self.walletReference.balance == self.balanceBeforeTransfer: "Dapper Coin leakage"
    }
}
