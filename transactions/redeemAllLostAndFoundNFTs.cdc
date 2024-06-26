import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import Dandy from "../contracts/Dandy.cdc"
import NFGv3 from "../contracts/NFGv3.cdc"
import PartyFavorz from "../contracts/PartyFavorz.cdc"
import NameVoucher from "../contracts/NameVoucher.cdc"
import Wearables from "../contracts/community/Wearables.cdc"
import FindPack from "../contracts/FindPack.cdc"

//IMPORT

transaction() {

    let ids : {String : [UInt64]}
    let nftInfos : {String : NFTCatalog.NFTCollectionData}
    let receiverAddress : Address

    prepare(account: AuthAccount){

        //LINK
        // Dandy
        let DandyRef= account.borrow<&Dandy.Collection>(from: Dandy.CollectionStoragePath)
        if DandyRef == nil {
            account.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
            account.unlink(Dandy.CollectionPublicPath)
            account.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
                Dandy.CollectionPublicPath,
                target: Dandy.CollectionStoragePath
            )
            account.unlink(Dandy.CollectionPrivatePath)
            account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
                Dandy.CollectionPrivatePath,
                target: Dandy.CollectionStoragePath
            )
        }

        let DandyCap= account.getCapability<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(Dandy.CollectionPublicPath)
        if !DandyCap.check() {
            account.unlink(Dandy.CollectionPublicPath)
            account.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
                Dandy.CollectionPublicPath,
                target: Dandy.CollectionStoragePath
            )
        }

        let DandyProviderCap= account.getCapability<&Dandy.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(Dandy.CollectionPrivatePath)
        if !DandyProviderCap.check() {
            account.unlink(Dandy.CollectionPrivatePath)
            account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
                Dandy.CollectionPrivatePath,
                target: Dandy.CollectionStoragePath
            )
        }

        //findPack
        let FindPackRef= account.borrow<&FindPack.Collection>(from: FindPack.CollectionStoragePath)
        if FindPackRef == nil {
            account.save<@NonFungibleToken.Collection>(<- FindPack.createEmptyCollection(), to: FindPack.CollectionStoragePath)
            account.unlink(FindPack.CollectionPublicPath)
            account.link<&FindPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                FindPack.CollectionPublicPath,
                target: FindPack.CollectionStoragePath
            )
            account.unlink(FindPack.CollectionPrivatePath)
            account.link<&FindPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                FindPack.CollectionPrivatePath,
                target: FindPack.CollectionStoragePath
            )
        }

        let FindPackCap= account.getCapability<&FindPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FindPack.CollectionPublicPath)
        if !FindPackCap.check() {
            account.unlink(FindPack.CollectionPublicPath)
            account.link<&FindPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                FindPack.CollectionPublicPath,
                target: FindPack.CollectionStoragePath
            )
        }

        let FindPackProviderCap= account.getCapability<&FindPack.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(FindPack.CollectionPrivatePath)
        if !FindPackProviderCap.check() {
            account.unlink(FindPack.CollectionPrivatePath)
            account.link<&FindPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                FindPack.CollectionPrivatePath,
                target: FindPack.CollectionStoragePath
            )
        }

        // NFGv3
        let NFGv3Ref= account.borrow<&NFGv3.Collection>(from: NFGv3.CollectionStoragePath)
        if NFGv3Ref == nil {
            account.save<@NonFungibleToken.Collection>(<- NFGv3.createEmptyCollection(), to: NFGv3.CollectionStoragePath)
            account.unlink(NFGv3.CollectionPublicPath)
            account.link<&NFGv3.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                NFGv3.CollectionPublicPath,
                target: NFGv3.CollectionStoragePath
            )
            account.unlink(NFGv3.CollectionPrivatePath)
            account.link<&NFGv3.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                NFGv3.CollectionPrivatePath,
                target: NFGv3.CollectionStoragePath
            )
        }

        let NFGv3Cap= account.getCapability<&NFGv3.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NFGv3.CollectionPublicPath)
        if !NFGv3Cap.check() {
            account.unlink(NFGv3.CollectionPublicPath)
            account.link<&NFGv3.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                NFGv3.CollectionPublicPath,
                target: NFGv3.CollectionStoragePath
            )
        }

        let NFGv3ProviderCap= account.getCapability<&NFGv3.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NFGv3.CollectionPrivatePath)
        if !NFGv3ProviderCap.check() {
            account.unlink(NFGv3.CollectionPrivatePath)
            account.link<&NFGv3.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                NFGv3.CollectionPrivatePath,
                target: NFGv3.CollectionStoragePath
            )
        }

        // Party Favorz
        let PartyFavorzRef= account.borrow<&PartyFavorz.Collection>(from: PartyFavorz.CollectionStoragePath)
        if PartyFavorzRef == nil {
            account.save<@NonFungibleToken.Collection>(<- PartyFavorz.createEmptyCollection(), to: PartyFavorz.CollectionStoragePath)
            account.unlink(PartyFavorz.CollectionPublicPath)
            account.link<&PartyFavorz.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                PartyFavorz.CollectionPublicPath,
                target: PartyFavorz.CollectionStoragePath
            )
            account.unlink(PartyFavorz.CollectionPrivatePath)
            account.link<&PartyFavorz.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                PartyFavorz.CollectionPrivatePath,
                target: PartyFavorz.CollectionStoragePath
            )
        }

        let PartyFavorzCap= account.getCapability<&PartyFavorz.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(PartyFavorz.CollectionPublicPath)
        if !PartyFavorzCap.check() {
            account.unlink(PartyFavorz.CollectionPublicPath)
            account.link<&PartyFavorz.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                PartyFavorz.CollectionPublicPath,
                target: PartyFavorz.CollectionStoragePath
            )
        }

        let PartyFavorzProviderCap= account.getCapability<&PartyFavorz.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(PartyFavorz.CollectionPrivatePath)
        if !PartyFavorzProviderCap.check() {
            account.unlink(PartyFavorz.CollectionPrivatePath)
            account.link<&PartyFavorz.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                PartyFavorz.CollectionPrivatePath,
                target: PartyFavorz.CollectionStoragePath
            )
        }

        // Name Voucher
        let nameVoucherRef= account.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
        if nameVoucherRef == nil {
            account.save<@NonFungibleToken.Collection>(<- NameVoucher.createEmptyCollection(), to: NameVoucher.CollectionStoragePath)
            account.unlink(NameVoucher.CollectionPublicPath)
            account.link<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                NameVoucher.CollectionPublicPath,
                target: NameVoucher.CollectionStoragePath
            )
            account.unlink(NameVoucher.CollectionPrivatePath)
            account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                NameVoucher.CollectionPrivatePath,
                target: NameVoucher.CollectionStoragePath
            )
        }

        let nameVoucherCap= account.getCapability<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NameVoucher.CollectionPublicPath)
        if !nameVoucherCap.check() {
            account.unlink(NameVoucher.CollectionPublicPath)
            account.link<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                NameVoucher.CollectionPublicPath,
                target: NameVoucher.CollectionStoragePath
            )
        }

        let nameVoucherProviderCap= account.getCapability<&NameVoucher.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NameVoucher.CollectionPrivatePath)
        if !nameVoucherProviderCap.check() {
            account.unlink(NameVoucher.CollectionPrivatePath)
            account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                NameVoucher.CollectionPrivatePath,
                target: NameVoucher.CollectionStoragePath
            )
        }

        // Wearables
        let wearablesRef= account.borrow<&Wearables.Collection>(from: Wearables.CollectionStoragePath)
        if wearablesRef == nil {
            account.save<@NonFungibleToken.Collection>(<- Wearables.createEmptyCollection(), to: Wearables.CollectionStoragePath)
            account.unlink(Wearables.CollectionPublicPath)
            account.link<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                Wearables.CollectionPublicPath,
                target: Wearables.CollectionStoragePath
            )
            account.unlink(Wearables.CollectionPrivatePath)
            account.link<&Wearables.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                Wearables.CollectionPrivatePath,
                target: Wearables.CollectionStoragePath
            )
        }

        let wearablesCap= account.getCapability<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Wearables.CollectionPublicPath)
        if !wearablesCap.check() {
            account.unlink(Wearables.CollectionPublicPath)
            account.link<&Wearables.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                Wearables.CollectionPublicPath,
                target: Wearables.CollectionStoragePath
            )
        }

        let wearablesProviderCap= account.getCapability<&Wearables.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Wearables.CollectionPrivatePath)
        if !wearablesProviderCap.check() {
            account.unlink(Wearables.CollectionPrivatePath)
            account.link<&Wearables.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                Wearables.CollectionPrivatePath,
                target: Wearables.CollectionStoragePath
            )
        }

        self.nftInfos = {}
        self.ids = FindLostAndFoundWrapper.getTicketIDs(user: account.address, specificType: Type<@NonFungibleToken.NFT>())

        for type in self.ids.keys{
            if self.nftInfos[type] == nil {
                let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type) ?? panic("NFT type is not supported at the moment. Type : ".concat(type))
                self.nftInfos[type] = FINDNFTCatalog.getCatalogEntry(collectionIdentifier: collections.keys[0])!.collectionData
            }
        }

        self.receiverAddress = account.address
    }

    execute{
        for type in self.ids.keys{
            let path = self.nftInfos[type]!.publicPath
            for id in self.ids[type]! {
                FindLostAndFoundWrapper.redeemNFT(type: CompositeType(type)!, ticketID: id, receiverAddress: self.receiverAddress, collectionPublicPath: path)
            }
        }
    }
}

