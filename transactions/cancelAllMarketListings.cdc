import "FindMarket"
import "FindMarketDirectOfferEscrow"
import "FindMarketAuctionEscrow"
import "FindMarketAuctionSoft"
import "FindMarketDirectOfferSoft"
import "FindMarketSale"

transaction() {
	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)

		if let saleItems= account.storage.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())) {
			var ids = saleItems.getIds()
			for id in ids {
				saleItems.cancel(id)
			}
		}

		if let saleItem2= account.storage.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionEscrow.SaleItemCollection>())) {
			var ids = saleItem2.getIds()
			for id in ids {
				saleItem2.cancel(id)
			}
		}

		if let saleItems3= account.storage.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>())) {
			var ids = saleItems3.getIds()
			for id in ids {
				saleItems3.cancel(id)
			}
		}

		if let saleItems4= account.storage.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())) {
			var ids = saleItems4.getIds()
			for id in ids {
				saleItems4.cancel(id)
			}
		}

		if let saleItems5= account.storage.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>())) {
			var ids = saleItems5.getIds()
			for id in ids {
				saleItems5.delist(id)
			}
		}
	}
}
