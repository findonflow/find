import FIND from "../contracts/FIND.cdc"

transaction(name: String, directSellPrice:UFix64) {

    let finLeases : &FIND.LeaseCollection?

    prepare(acct: auth(BorrowValue) &Account) {
        self.finLeases= acct.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
    }

    pre{
        self.finLeases != nil : "Cannot borrow reference to find lease collection"
    }

    execute{
        self.finLeases!.listForSale(name: name,  directSellPrice:directSellPrice)
    }
}
