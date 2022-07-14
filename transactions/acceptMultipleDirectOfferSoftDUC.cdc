import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(dapperAddress: Address, marketplace:Address, ids: [UInt64]) {

	let market : &FindMarketDirectOfferSoft.SaleItemCollection
	let pointer : [FindViews.AuthNFTPointer]

	prepare(account: AuthAccount) {

		let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !ducReceiver.check() {
			let dapper = getAccount(dapperAddress)
			// Create a new Forwarder resource for DUC and store it in the new account's storage
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
			// Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinReceiver)
		}

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!
		if !profile.hasWallet("DUC") {
			profile.addWallet(Profile.Wallet( name:"DUC", receiver:ducReceiver, balance:getAccount(dapperAddress).getCapability<&{FungibleToken.Balance}>(/public/dapperUtilityCoinBalance), accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapperUtilityCoin","dapper"]))
			profile.emitUpdatedEvent()
		}

		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
		self.market = account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())

		var counter = 0
		self.pointer = []
		let nfts : {String : NFTRegistry.NFTInfo} = {}

		while counter < ids.length {
			let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: ids[counter])
			var nft : NFTRegistry.NFTInfo? = nil
			let nftIdentifier = item.getItemType().identifier
			let ftType = item.getFtType()

			if nfts[nftIdentifier] != nil {
				nft = nfts[nftIdentifier]
			} else {
				nft = NFTRegistry.getNFTInfo(nftIdentifier) ?? panic("This NFT is not supported by the Find Market yet. Type : ".concat(nftIdentifier))
				nfts[nftIdentifier] = nft
			}

			let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft!.providerPath)
			let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
			self.pointer.append(pointer)
			counter = counter + 1
		}

	}

	execute {
		var counter = 0
		while counter < ids.length {
			self.market.acceptOffer(self.pointer[counter])
			counter = counter + 1
		}
	}
	
}
