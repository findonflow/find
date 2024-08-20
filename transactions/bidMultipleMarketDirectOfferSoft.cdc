import "FindMarketDirectOfferSoft"
import "FindMarket"
import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "FTRegistry"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FIND"

transaction(users: [String], nftAliasOrIdentifiers: [String], ids: [UInt64], ftAliasOrIdentifiers:[String], amounts: [UFix64], validUntil: UFix64?) {

	let targetCapability : [Capability<&{NonFungibleToken.Receiver}>]
	let walletReference : [&FungibleToken.Vault]
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection?
	let pointer: [FindViews.ViewReadPointer]
	let ftVaultType: [Type]
	let totalPrice : {String : UFix64}

	prepare(account: auth(BorrowValue) &Account) {

		if nftAliasOrIdentifiers.length != users.length {
			panic("The length of arrays passed in has to be the same")
		} else if nftAliasOrIdentifiers.length != ids.length {
			panic("The length of arrays passed in has to be the same")
		} else if nftAliasOrIdentifiers.length != ftAliasOrIdentifiers.length {
			panic("The length of arrays passed in has to be the same")
		} else if nftAliasOrIdentifiers.length != amounts.length {
			panic("The length of arrays passed in has to be the same")
		}

		let marketplace = FindMarket.getFindTenantAddress()
		let addresses : {String : Address} = {}
		let nfts : {String : NFTCatalog.NFTCollectionData} = {}
		let fts : {String : FTRegistry.FTInfo} = {}
		let vaultRefs : {StoragePath : &FungibleToken.Vault} = {}

		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!
		let bidStoragePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.storage.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: bidStoragePath)
		self.walletReference = []
		self.pointer = []
		self.targetCapability = []
		self.ftVaultType = []
		self.totalPrice = {}

		var counter = 0
		while counter < users.length {
			var resolveAddress : Address? = nil
			if addresses[users[counter]] != nil {
				resolveAddress = addresses[users[counter]]!
			} else {
				let address = FIND.resolve(users[counter])
				if address == nil {
					panic("The address input is not a valid name nor address. Input : ".concat(users[counter]))
				}
				addresses[users[counter]] = address!
				resolveAddress = address!
			}
			let address = resolveAddress!

			var nft : NFTCatalog.NFTCollectionData? = nil
			var ft : FTRegistry.FTInfo? = nil
			let nftIdentifier = nftAliasOrIdentifiers[counter]
			let ftIdentifier = ftAliasOrIdentifiers[counter]

			if nfts[nftIdentifier] != nil {
				nft = nfts[nftIdentifier]
			} else {
				let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
				let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
				nft = collection.collectionData
				nfts[nftIdentifier] = nft
			}

			if fts[ftIdentifier] != nil {
				ft = fts[ftIdentifier]
			} else {
				ft = FTRegistry.getFTInfo(ftIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftIdentifier))
				fts[ftIdentifier] = ft
			}

			if vaultRefs[ft!.vaultPath] != nil {
				self.walletReference.append(vaultRefs[ft!.vaultPath]!)
				self.ftVaultType.append(vaultRefs[ft!.vaultPath]!.getType())
			} else {
				let walletReference = account.storage.borrow<&{FungibleToken.Vault}>(from: ft!.vaultPath) ?? panic("No suitable wallet linked for this account")
				vaultRefs[ft!.vaultPath] = walletReference
				self.walletReference.append(walletReference)
				self.ftVaultType.append(ft!.type)
			}

			if self.totalPrice[ftIdentifier] == nil {
				self.totalPrice[ftIdentifier] = amounts[counter]
			} else {
				self.totalPrice[ftIdentifier] = self.totalPrice[ftIdentifier]! + amounts[counter]
			}

			let pointer= FindViews.createViewReadPointer(address: address, path:nft!.publicPath, id: ids[counter])
			self.pointer.append(pointer)

			var targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft!.publicPath)

			/* Check for nftCapability */
			if !targetCapability.check() {
				let cd = pointer.getNFTCollectionData()
				// should use account.type here instead
				if account.type(at: cd.storagePath) != nil {
					let pathIdentifier = nft!.publicPath.toString()
					let findPath = PublicPath(identifier: pathIdentifier.slice(from: "/public/".length , upTo: pathIdentifier.length).concat("_FIND"))!
					account.link<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
						findPath,
						target: nft!.storagePath
					)
					targetCapability = account.getCapability<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(findPath)
				} else {
					account.storage.save(<- cd.createEmptyCollection(), to: cd.storagePath)
					account.link<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
				}

			}
			self.targetCapability.append(targetCapability)
			counter = counter + 1
		}
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		var counter = 0
		while counter < ids.length {
			if self.walletReference[counter].balance < self.totalPrice[ftAliasOrIdentifiers[counter]]! {
				panic("Your wallet does not have enough funds to pay for this item. Vault Type : ".concat(self.ftVaultType[counter].getType().identifier).concat(" . Required : ".concat(self.totalPrice[ftAliasOrIdentifiers[counter]]!.toString())))
			}
			self.bidsReference!.bid(item:self.pointer[counter], amount: amounts[counter], vaultType: self.ftVaultType[counter], nftCap: self.targetCapability[counter], validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
			counter = counter + 1
		}
	}
}
