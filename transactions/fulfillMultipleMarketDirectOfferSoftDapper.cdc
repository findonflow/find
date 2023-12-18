import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(ids: [UInt64], amounts:[UFix64]) {

	let walletReference : [&FungibleToken.Vault]
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection
	let requiredAmount: [UFix64]
	let balanceBeforeTransfer: {Type : UFix64}

	prepare(dapper: auth(BorrowValue)  AuthAccountAccount, account: auth(BorrowValue)  AuthAccountAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath) ?? panic("Cannot borrow direct offer soft bid collection")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())

		var counter = 0
		self.requiredAmount = []
		self.walletReference = []
		self.balanceBeforeTransfer = {}
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
				let vaultRef = vaultRefs[ft!.vaultPath]!
				self.walletReference.append(vaultRef)
			} else {
				let walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft!.vaultPath) ?? panic("Cannot borrow Dapper Coin Vault. Type : ".concat(ft!.type.identifier))
				vaultRefs[ft!.vaultPath] = walletReference
				self.walletReference.append(walletReference)
				self.balanceBeforeTransfer[walletReference.getType()] = walletReference.balance
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
		// Check that all dapper Coin was routed back to Dapper
		for vault in self.walletReference {
			if self.balanceBeforeTransfer[vault.getType()]! != vault.balance {
				panic("Dapper Coin leakage. Type : ".concat(vault.getType().identifier))
			}
		}
	}

}

