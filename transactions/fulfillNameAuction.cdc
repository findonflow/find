import "FIND"
import "Profile"

transaction(owner: Address, name: String) {

    let leases : &FIND.LeaseCollection?

    prepare(account: &Account) {
        self.leases = getAccount(owner).capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)!.borrow()
    }

    pre{
        self.leases != nil : "Cannot borrow reference to lease collection reference. Account address: ".concat(owner.toString())
    }

    execute{
        self.leases!.fulfillAuction(name)
    }
}
