import "Profile"
import "FIND"


transaction(name: String, receiver:String) {


    let receiverAddress:Address?
    //TODO: what entitlement is correct here?
    let sender : auth(FIND.Leasee) &FIND.LeaseCollection

    prepare(acct: auth(BorrowValue) &Account) {
        self.sender= acct.storage.borrow<auth(FIND.Leasee) &FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("You do not have a profile set up, initialize the user first")
        self.receiverAddress=FIND.resolve(receiver)
    } 

    pre{
        self.receiverAddress != nil : "The input pass in is not a valid name or address. Input : ".concat(receiver)
    }

    execute {
        let receiver=getAccount(self.receiverAddress!)
        let receiverLease = receiver.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)
        let receiverProfile = receiver.capabilities.get<&{Profile.Public}>(Profile.publicPath)



        if !receiverLease.check() || !receiverProfile.check() {
            panic("Not a valid FIND user")
        }

        self.sender.move(name:name, profile:receiverProfile, to: receiverLease)
    }
}
