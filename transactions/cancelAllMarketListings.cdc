import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

transaction(marketplace:Address) {
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)

		if let saleItems= account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())) {
			var ids = saleItems.getIds()
			for id in ids {
				saleItems.cancel(id)
			}
		}

		if let saleItem2= account.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionEscrow.SaleItemCollection>())) {
			var ids = saleItem2.getIds()
			for id in ids {
				saleItem2.cancel(id)
			}
		}

		if let saleItems3= account.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>())) {
			var ids = saleItems3.getIds()
			for id in ids {
				saleItems3.cancel(id)
			}
		}

		if let saleItems4= account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())) {
			var ids = saleItems4.getIds()
			for id in ids {
				saleItems4.cancel(id)
			}
		}

		if let saleItems5= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>())) {
			var ids = saleItems5.getIds()
			for id in ids {
				saleItems5.delist(id)
			}
		}
	}
}
