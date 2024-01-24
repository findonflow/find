import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(ids: [UInt64], amounts:[UFix64]) {

	let walletReference : [&FungibleToken.Vault]
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection
	let requiredAmount: [UFix64]

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.storage.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath) ?? panic("Cannot borrow direct offer soft bid collection")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())

		var counter = 0
		self.requiredAmount = []
		self.walletReference = []
		let fts : {String : FTRegistry.FTInfo} = {}
		let vaultRefs : {StoragePath : &FungibleToken.Vault} = {}


		while counter < ids.length {
			let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: ids[counter])

			var ft : FTRegistry.FTInfo? = nil
			let ftIdentifier = item.getFtType().identifier
			if fts[ftIdentifier] != nil {
				ft = fts[ftIdentifier]
			} else {
				ft = FTRegistry.getFTInfoByTypeIdentifier(ftIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftIdentifier))
				fts[ftIdentifier] = ft
			}

			if vaultRefs[ft!.vaultPath] != nil {
				self.walletReference.append(vaultRefs[ft!.vaultPath]!)
			} else {
				let walletReference = account.storage.borrow<&{FungibleToken.Vault}>(from: ft!.vaultPath) ?? panic("No suitable wallet linked for this account")
				vaultRefs[ft!.vaultPath] = walletReference
				self.walletReference.append(walletReference)
			}
			let requiredAmount = self.bidsReference.getBalance(ids[counter])
			self.requiredAmount.append(requiredAmount)
			counter = counter + 1
		}
	}

	execute {
		var counter = 0
		while counter < ids.length {
			if self.walletReference[counter].balance < self.requiredAmount[counter] {
				panic("Your wallet does not have enough funds to pay for this item. Item ID: ".concat(ids[counter].toString()))
			}
			if self.requiredAmount[counter] != amounts[counter] {
				panic("Amount needed to fulfill is ".concat(amounts[counter].toString()))
			}
			let vault <- self.walletReference[counter].withdraw(amount: amounts[counter])
			self.bidsReference.fulfillDirectOffer(id: ids[counter], vault: <- vault)
			counter = counter + 1
		}
	}
}

