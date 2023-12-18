import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(users: [Address], ids: [UInt64], amounts: [UFix64]) {

	let targetCapability : [Capability<&{NonFungibleToken.Receiver}>]
	var walletReference : [&FungibleToken.Vault]

	let saleItems: [&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}]
	var totalPrice : UFix64
	let prices : [UFix64]
	prepare(account: AuthAccount) {

		let marketplace = FindMarket.getFindTenantAddress()
		if users.length != ids.length {
			panic("The array length of users and ids should be the same")
		}

		//the code below has some dead code for this specific transaction, but it is hard to maintain otherwise

		var counter = 0
		self.walletReference= []
		self.targetCapability = []

		self.saleItems = []
		let nfts : {String : NFTCatalog.NFTCollectionData} = {}
		let fts : {String : FTRegistry.FTInfo} = {}
		let saleItems : {Address : &FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}} = {}

		let saleItemType = Type<@FindMarketSale.SaleItemCollection>()
		let marketOption = FindMarket.getMarketOptionFromType(saleItemType)

		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!
		let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
		let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

		let saleItemCap= account.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath)
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}

		var vaultType : Type? = nil

		self.totalPrice = 0.0
		self.prices = []

		while counter < users.length {

			let address=users[counter]

			if saleItems[address] == nil {
				let saleItem = getAccount(address).getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath).borrow() ?? panic("cannot find sale item cap")
				self.saleItems.append(saleItem)
				saleItems[address] = saleItem
			} else {
				self.saleItems.append(saleItems[address]!)
			}


			// let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: ids[counter])
			let item=saleItems[address]!.borrowSaleItem(ids[counter])

			self.prices.append(item.getBalance())
			self.totalPrice = self.totalPrice + self.prices[counter]

			var nft : NFTCatalog.NFTCollectionData? = nil
			var ft : FTRegistry.FTInfo? = nil
			let nftIdentifier = item.getItemType().identifier
			let ftIdentifier = item.getFtType().identifier

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

			self.walletReference.append(
				account.borrow<&FungibleToken.Vault>(from: ft!.vaultPath) ?? panic("No suitable wallet linked for this account")
			)

			var targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft!.publicPath)
			/* Check for nftCapability */
			if !targetCapability.check() {
				let cd = item.getNFTCollectionData()
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
					account.save(<- cd.createEmptyCollection(), to: cd.storagePath)
					account.link<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
					account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
				}

			}
			self.targetCapability.append(targetCapability)
			counter = counter + 1
		}


	}

	execute {
		var counter = 0
		while counter < users.length {
			if self.prices[counter] != amounts[counter] {
				panic("Please pass in the correct price of the buy items. Required : ".concat(self.prices[counter].toString()).concat(" . saleItem ID : ".concat(ids[counter].toString())))
			}
			if self.walletReference[counter].balance < amounts[counter] {
				panic("Your wallet does not have enough funds to pay for this item. Required : ".concat(self.prices[counter].toString()).concat(" . saleItem ID : ".concat(ids[counter].toString())))
			}

			self.saleItems[counter].buy(id:ids[counter], vault: <- self.walletReference[counter].withdraw(amount: amounts[counter])
			, nftCap: self.targetCapability[counter])
			counter = counter + 1
		}
	}
}
