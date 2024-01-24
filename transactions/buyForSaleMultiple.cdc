import FUSD from "../contracts/standard/FUSD.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(users: [Address], ids: [AnyStruct], amounts: [UFix64]) {

	let targetCapability : [Capability<&{NonFungibleToken.Receiver}>]
	var walletReference : [&FungibleToken.Vault]

	let saleItems: [&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}]
	let leaseNames: [String]
	let leaseBidReference: &FIND.BidCollection
	var totalPrice : UFix64
	let prices : [UFix64]
	let buyer : Address

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		if users.length != ids.length {
			panic("The array length of users and ids should be the same")
		}

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
			account.storage.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}

		self.buyer = account.address
		self.leaseNames = []
		self.leaseBidReference = account.storage.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath) ?? panic("Could not borrow reference to the bid collection!" )

		var vaultType : Type? = nil

		self.totalPrice = 0.0
		self.prices = []

		while counter < users.length {

			let address=users[counter]

			if let name = ids[counter] as? String {
				let targetAddress = FIND.lookupAddress(name) ?? panic("Cannot look up address for name : ".concat(name))
				let leaseCap = getAccount(targetAddress).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
				let leaseRef = leaseCap.borrow() ?? panic("Cannot borrow reference from name owner. Name : ".concat(name))
				let nameInfo = leaseRef.getLease(name)!
				let price = nameInfo.salePrice ?? panic("Name is not listed for sale. Name : ".concat(name))
				self.prices.append(price)
				self.leaseNames.append(name)

				self.walletReference.append(
					account.storage.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No suitable wallet linked for this account")
				)
			}

			if let id = ids[counter] as? UInt64 {
				if saleItems[address] == nil {
					let saleItem = getAccount(address).getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath).borrow() ?? panic("cannot find target sale item cap. ID : ".concat(id.toString()))
					self.saleItems.append(saleItem)
					saleItems[address] = saleItem
				} else {
					self.saleItems.append(saleItems[address]!)
				}

				let item=saleItems[address]!.borrowSaleItem(id)

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
					account.storage.borrow<&{FungibleToken.Vault}>(from: ft!.vaultPath) ?? panic("No suitable wallet linked for this account")
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
						account.storage.save(<- cd.createEmptyCollection(), to: cd.storagePath)
						account.link<&{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
						account.link<&{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
					}

				}
				self.targetCapability.append(targetCapability)
			}
			counter = counter + 1
		}


	}

	execute {
		var counter = 0
		var nameCounter = 0
		for i, input in ids {

			if let name = input as? String {
				if self.prices[i] != amounts[i] {
					panic("Please pass in the correct price of the name. Required : ".concat(self.prices[i].toString()).concat(" . Name : ".concat(name)))
				}
				if self.walletReference[i].balance < amounts[i] {
					panic("Your wallet does not have enough funds to pay for this name. Required : ".concat(self.prices[i].toString()).concat(" . Name : ".concat(name)))
				}

				let vault <- self.walletReference[i].withdraw(amount: self.prices[i]) as! @FUSD.Vault
				self.leaseBidReference.bid(name: name, vault: <- vault)
				nameCounter = nameCounter + 1
				continue
			}

			let id = input as! UInt64
			if self.prices[i] != amounts[i] {
				panic("Please pass in the correct price of the buy items. Required : ".concat(self.prices[i].toString()).concat(" . saleItem ID : ".concat(id.toString())))
			}
			if self.walletReference[i].balance < amounts[i] {
				panic("Your wallet does not have enough funds to pay for this item. Required : ".concat(self.prices[i].toString()).concat(" . saleItem ID : ".concat(id.toString())))
			}

			self.saleItems[counter].buy(id:id, vault: <- self.walletReference[i].withdraw(amount: amounts[i])
			, nftCap: self.targetCapability[counter])
			counter = counter + 1
		}
	}
}
