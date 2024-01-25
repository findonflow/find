import Profile from "../contracts/Profile.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(user: String, nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier:String, amount: UFix64, validUntil: UFix64?) {

	var targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : auth(FungibleToken.Withdrawable) &{FungibleToken.Vault}
	let bidsReference: &FindMarketDirectOfferEscrow.MarketBidCollection?
	let pointer: FindViews.ViewReadPointer

	prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
		let address = resolveAddress!

		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)
		self.walletReference = account.storage.borrow<auth(FungibleToken.Withdrawable) &FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")

		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!

		let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
		let doeBidType= Type<@FindMarketDirectOfferEscrow.MarketBidCollection>()
		let doeBidPublicPath=FindMarket.getPublicPath(doeBidType, name: tenant.name)
		let doeBidStoragePath= FindMarket.getStoragePath(doeBidType, name:tenant.name)
		let doeBidCap= account.getCapability<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(doeBidPublicPath)
		if !doeBidCap.check() {
			account.storage.save<@FindMarketDirectOfferEscrow.MarketBidCollection>(<- FindMarketDirectOfferEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: doeBidStoragePath)
			account.link<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(doeBidPublicPath, target: doeBidStoragePath)
		}

		self.bidsReference= account.storage.borrow<&FindMarketDirectOfferEscrow.MarketBidCollection>(from: doeBidStoragePath)
		self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: id)

		/* Check for nftCapability */
		let col= account.storage.borrow<&AnyResource>(from: nft.storagePath) as? &{NonFungibleToken.Collection}?
        if col == nil {
            let cd = self.pointer.getNFTCollectionData()
            account.storage.save(<- cd.createEmptyCollection(), to: cd.storagePath)
            account.capabilities.unpublish(cd.publicPath)
            let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
            account.capabilities.publish(cap, at: cd.publicPath)
            self.targetCapability=cap
        } else {
            //TODO: I do not think this works as intended
            var targetCapability= account.capabilities.get<&AnyResource>(nft.publicPath) as? Capability<&{NonFungibleToken.Collection}>
            if targetCapability == nil || !targetCapability!.check() {
                let cd = self.pointer.getNFTCollectionData()
                let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
                account.capabilities.unpublish(cd.publicPath)
                account.capabilities.publish(cap, at: cd.publicPath)
                targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath)
            }
			self.targetCapability=targetCapability!
		}
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
		self.walletReference.getBalance() > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount)
		self.bidsReference!.bid(item:self.pointer, vault: <- vault, nftCap: self.targetCapability, validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
	}

}
