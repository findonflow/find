import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(marketplace:Address, users: [Address], ids: [AnyStruct], amounts: [UFix64]) {

	let targetCapability : [Capability<&{NonFungibleToken.Receiver}>]
	var walletReference : [&FungibleToken.Vault]

	let saleItems: [&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}]
	let leaseSaleItems: [&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}]
	var totalPrice : UFix64
	let prices : [UFix64]
	let buyer : Address

	prepare(account: AuthAccount) {

		if users.length != ids.length {
			panic("The array length of users and ids should be the same")
		}

		var counter = 0
		self.walletReference= []
		self.targetCapability = []
		self.leaseSaleItems = []

		self.saleItems = []
		let nfts : {String : NFTCatalog.NFTCollectionData} = {}
		let fts : {String : FTRegistry.FTInfo} = {}
		let saleItems : {Address : &FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}} = {}
		let leaseSaleItems : {Address : &FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}} = {}

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

		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!

		let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
		let leasePublicPath=FindMarket.getPublicPath(leaseSaleItemType, name: "findLease")
		let leaseStoragePath= FindMarket.getStoragePath(leaseSaleItemType, name:"findLease")
		let leaseSaleItemCap= account.getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath)
		if !leaseSaleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
			account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath, target: leaseStoragePath)
		}

		self.buyer = account.address

		var vaultType : Type? = nil

		self.totalPrice = 0.0
		self.prices = []

		while counter < users.length {

			let address=users[counter]

			if let name = ids[counter] as? String {
				if leaseSaleItems[address] == nil {
					let saleItem = getAccount(address).getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath).borrow() ?? panic("cannot find target sale item cap. Name : ".concat(name))
					self.leaseSaleItems.append(saleItem)
					leaseSaleItems[address] = saleItem
				} else {
					self.leaseSaleItems.append(leaseSaleItems[address]!)
				}

				let item=leaseSaleItems[address]!.borrowSaleItem(name)

				self.prices.append(item.getBalance())
				self.totalPrice = self.totalPrice + self.prices[counter]

				var ft : FTRegistry.FTInfo? = nil
				let ftIdentifier = item.getFtType().identifier

				if fts[ftIdentifier] != nil {
					ft = fts[ftIdentifier]
				} else {
					ft = FTRegistry.getFTInfo(ftIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftIdentifier))
					fts[ftIdentifier] = ft
				}

				self.walletReference.append(
					account.borrow<&FungibleToken.Vault>(from: ft!.vaultPath) ?? panic("No suitable wallet linked for this account")
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
						account.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
							findPath,
							target: nft!.storagePath
						)
						targetCapability = account.getCapability<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
					} else {
						account.save(<- cd.createEmptyCollection(), to: cd.storagePath)
						account.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
						account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
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

				self.leaseSaleItems[nameCounter].buy(name: name, vault: <- self.walletReference[i].withdraw(amount: amounts[i])
				, to: self.buyer)
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
