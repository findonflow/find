import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import FindRewardToken from "../contracts/FindRewardToken.cdc"

transaction(marketplace:Address, users: [Address], ids: [UInt64], amounts: [UFix64]) {

	let targetCapability : [Capability<&{NonFungibleToken.Receiver}>]
	var walletReference : [&FungibleToken.Vault]

	let saleItems: [&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}]
	var totalPrice : UFix64
	let prices : [UFix64]
	prepare(account: AuthAccount) {

		if users.length != ids.length {
			panic("The array length of users and ids should be the same")
		}

		//the code below has some dead code for this specific transaction, but it is hard to maintain otherwise


		var counter = 0
		self.walletReference= []
		self.targetCapability = []

		self.saleItems = []
		let nfts : {String : NFTRegistry.NFTInfo} = {}
		let fts : {String : FTRegistry.FTInfo} = {}
		let saleItems : {Address : &FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}} = {}

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())

		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let tenant = tenantCapability.borrow()!
		let publicPath=FindMarket.getPublicPath(Type<@FindMarketSale.SaleItemCollection>(), name: tenant.name)
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
			
			var nft : NFTRegistry.NFTInfo? = nil
			var ft : FTRegistry.FTInfo? = nil
			let nftIdentifier = item.getItemType().identifier
			let ftIdentifier = item.getFtType().identifier

			if nfts[nftIdentifier] != nil {
				nft = nfts[nftIdentifier]
			} else {
				nft = NFTRegistry.getNFTInfo(nftIdentifier) ?? panic("This NFT is not supported by the Find Market yet. Type : ".concat(nftIdentifier))
				nfts[nftIdentifier] = nft
			}

			if fts[ftIdentifier] != nil {
				ft = fts[ftIdentifier]
			} else {
				ft = FTRegistry.getFTInfo(ftIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftIdentifier))
				fts[ftIdentifier] = ft 
			}


			let walletReference = account.borrow<&FungibleToken.Vault>(from: ft!.vaultPath) ?? panic("No suitable wallet linked for this account")
			self.walletReference.append(walletReference)


			let targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft!.publicPath)
			/* Check for nftCapability */
			if !targetCapability.check() {
				let cd = item.getNFTCollectionData()
				// should use account.type here instead
				if account.borrow<&AnyResource>(from: cd.storagePath) != nil {
					panic("This collection public link is not set up properly.")
				}
				account.save(<- cd.createEmptyCollection(), to: cd.storagePath)
				account.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(cd.publicPath, target: cd.storagePath)
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(cd.providerPath, target: cd.storagePath)
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
		
			let vault <- self.walletReference[counter].withdraw(amount: amounts[counter]) 
			self.saleItems[counter].buy(id:ids[counter], vault: <- vault, nftCap: self.targetCapability[counter])
			counter = counter + 1
		}
	}
}
