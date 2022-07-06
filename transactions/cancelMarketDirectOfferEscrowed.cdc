import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"

transaction(marketplace:Address, ids: [UInt64]) {

	let saleItems : &FindMarketDirectOfferEscrow.SaleItemCollection?

	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		for id in ids {
			self.saleItems!.cancel(id)
		}
	}
}
