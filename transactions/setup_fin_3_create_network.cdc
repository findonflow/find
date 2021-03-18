

import FIN from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6

transaction(leasePeriod: UFix64, costPerLetter: UFix64, freeLetterTreshold: UInt64) {

    prepare(account: AuthAccount) {
        let wallet=account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)

        let adminClient=account.borrow<&FIN.Admin>(from: FIN.AdminClientStoragePath)!

        adminClient.createNetwork(
            admin: account, 
            leasePeriod: leasePeriod,
            lockPeriod: leasePeriod / 2.0, 
            costBaseNumber: costPerLetter, 
            baseLength: freeLetterTreshold, 
            wallet: wallet)
   }
}
 