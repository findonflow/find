import Profile from 0x35717efbbce11c74
import FIND from 0x35717efbbce11c74


transaction(name: String) {

    let leaseCollectionOwner : Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>
    let profile : &Profile.User

    prepare(acct: AuthAccount) {
        self.leaseCollectionOwner = acct.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
        self.profile =acct.borrow<&Profile.User>(from:Profile.storagePath)!
    }

    pre{
        self.leaseCollectionOwner.check() : "Not a find user"
        self.leaseCollectionOwner.borrow()!.getLease(name) != nil : "You do not own this lease so you cannot set it as main name"
    }

    execute{
        self.profile.setFindName(name)
    }
}
