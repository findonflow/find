import "FindMarket"
import "FindMarketDirectOfferEscrow"
import "FindMarketAuctionEscrow"
import "FindMarketAuctionSoft"
import "FindMarketDirectOfferSoft"
import "FindMarketSale"

transaction(ids: {String : [UInt64]}) {
	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)

		var saleType = Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()
		if let ids = ids[FindMarket.getMarketOptionFromType(saleType)] {
			let saleItems= account.storage.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(saleType))!
			for id in ids {
				saleItems.cancel(id)
			}
		}

		saleType = Type<@FindMarketAuctionEscrow.SaleItemCollection>()
		if let ids = ids[FindMarket.getMarketOptionFromType(saleType)] {
			let saleItems= account.storage.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(saleType))!
			for id in ids {
				saleItems.cancel(id)
			}
		}

		saleType = Type<@FindMarketAuctionSoft.SaleItemCollection>()
		if let ids = ids[FindMarket.getMarketOptionFromType(saleType)] {
			let saleItems= account.storage.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(saleType))!
			for id in ids {
				saleItems.cancel(id)
			}
		}

		saleType = Type<@FindMarketDirectOfferSoft.SaleItemCollection>()
		if let ids = ids[FindMarket.getMarketOptionFromType(saleType)] {
			let saleItems= account.storage.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(saleType))!
			for id in ids {
				saleItems.cancel(id)
			}
		}

		saleType = Type<@FindMarketSale.SaleItemCollection>()
		if let ids = ids[FindMarket.getMarketOptionFromType(saleType)] {
			let saleItems= account.storage.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(saleType))!
			for id in ids {
				saleItems.delist(id)
			}
		}

	}
}
