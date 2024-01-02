import Admin from "../contracts/Admin.cdc"
import FIND from "../contracts/FIND.cdc"
import GeneratedExperiences from "../contracts/GeneratedExperiences.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, season: [GeneratedExperiences.CollectionInfo]) {
    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {


        let col= account.storage.borrow<&GeneratedExperiences.Collection>(from: GeneratedExperiences.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- GeneratedExperiences.createEmptyCollection(), to: GeneratedExperiences.CollectionStoragePath)
            account.capabilities.unpublish(GeneratedExperiences.CollectionPublicPath)
            let cap = account.capabilities.storage.issue<&GeneratedExperiences.Collection>(GeneratedExperiences.CollectionStoragePath)
            account.capabilities.publish(cap, at: GeneratedExperiences.CollectionPublicPath)
        }

        let adminRef = account.storage.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let forgeType = GeneratedExperiences.getForgeType()
        if !FindForge.checkMinterPlatform(name: name, forgeType: forgeType ) {
            /* set up minterPlatform */
            adminRef.adminSetMinterPlatform(name: name,
            forgeType: forgeType,
            minterCut: 0.00,
            description: "setup for minter platform",
            externalURL: "setup for minter platform",
            squareImage: "setup for minter platform",
            bannerImage: "setup for minter platform",
            socials: {})
        }

        for i in season {
            adminRef.addForgeContractData(lease: name, forgeType: forgeType, data: i)
        }
    }
}

