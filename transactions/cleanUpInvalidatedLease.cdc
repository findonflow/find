import "FIND"


transaction(names: [String]) {

    let col : auth(FIND.LeaseOwner) &FIND.LeaseCollection

    prepare(acct: auth(BorrowValue) &Account) {
        self.col= acct.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("You do not have a profile set up, initialize the user first")
    }

    execute {
        for name in names {
            self.col.cleanUpInvalidatedLease(name)
        }
    }
}
