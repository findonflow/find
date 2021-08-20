import "../contracts/FiNS.cdc"


//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{FiNS.AdminProxyClient}>(FiNS.AdminProxyPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let admin=account.getCapability<&FiNS.Administrator>(FiNS.AdministratorPrivatePath)
        client.addCapability(admin)

    }
}
 
