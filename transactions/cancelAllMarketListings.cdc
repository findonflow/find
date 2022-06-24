import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

transaction(marketplace:Address) {
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)

		let saleItems= account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()))!
		var ids = saleItems.getIds()
		for id in ids {
			saleItems.cancel(id)
		}

		let saleItem2= account.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionEscrow.SaleItemCollection>()))!
		ids = saleItem2.getIds()
		for id in ids {
			saleItem2.cancel(id)
		}

		let saleItems3= account.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>()))!
		ids = saleItems3.getIds()
		for id in ids {
			saleItems3.cancel(id)
		}

		let saleItems4= account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>()))!
		ids = saleItems4.getIds()
		for id in ids {
			saleItems4.cancel(id)
		}

		let saleItems5= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))!
		ids = saleItems5.getIds()
		for id in ids {
			saleItems5.delist(id)
		}
	}
}
