import Admin from "../contracts/Admin.cdc"
import NameVoucher from "../contracts/NameVoucher.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

transaction(amount: Int, minCharLength: UInt64) {

    prepare(admin:AuthAccount) {

        let client= admin.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
        let cap = admin.getCapability<&{NonFungibleToken.Receiver}>(NameVoucher.CollectionPublicPath)
        let receiver = cap.borrow() ?? panic(admin.address.toString().concat(" did not setup name voucher collection."))
        var i=0
        while  i < amount {
            client.mintNameVoucher(receiver: receiver, minCharLength: minCharLength)
            i=i+1
        }
    }

}
