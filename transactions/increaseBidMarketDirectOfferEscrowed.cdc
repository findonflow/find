import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(id: UInt64, amount: UFix64) {

    let walletReference : auth(FungibleToken.Withdrawable) &{FungibleToken.Vault}
    let bidsReference: &FindMarketDirectOfferEscrow.MarketBidCollection
    let balanceBeforeBid: UFix64

    prepare(account: auth(BorrowValue) &Account) {
        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() ?? panic("Cannot borrow reference to tenant")
        let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.MarketBidCollection>())
        self.bidsReference= account.storage.borrow<&FindMarketDirectOfferEscrow.MarketBidCollection>(from: storagePath) ?? panic("This account does not have a bid collection")
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.MarketBidCollection>())
        let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)
        let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
        self.walletReference = account.storage.borrow<auth(FungibleToken.Withdrawable) &{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
        self.balanceBeforeBid=self.walletReference.getBalance()
    }

    pre {
        self.walletReference.getBalance() > amount : "Your wallet does not have enough funds to pay for this item"
    }

    execute {
        let vault <- self.walletReference.withdraw(amount: amount)
        self.bidsReference.increaseBid(id: id, vault: <- vault)
    }

}

