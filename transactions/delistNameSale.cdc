import "FIND"

transaction(names: [String]) {

    let finLeases : auth(FIND.LeaseOwner) &FIND.LeaseCollection?

    prepare(acct: auth(BorrowValue) &Account) {
        self.finLeases= acct.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
    }

    pre{
        self.finLeases != nil : "Cannot borrow reference to find lease collection"
    }

    execute{
        for name in names {
            self.finLeases!.delistSale(name)
        }
    }
}
