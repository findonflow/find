import FindForge from "../contracts/FindForge.cdc"

transaction() {
    prepare(account: auth(BorrowValue, SaveValue, PublishCapability, IssueStorageCapabilityController) &Account) {
        account.storage.save(<- FindForge.createForgeAdminProxyClient(), to:/storage/findForgeAdminProxy)
        let cap = account.capabilities.storage.issue<&{FindForge.ForgeAdminProxyClient}>(/storage/findForgeAdminProxy)
        account.capabilities.publish(cap, at: /public/findForgeAdminProxy)
    }
}
