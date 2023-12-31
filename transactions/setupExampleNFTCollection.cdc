import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import Debug from "../contracts/Debug.cdc"

transaction() {
    prepare(account: auth(BorrowValue, SaveValue, PublishCapability, IssueStorageCapabilityController,UnpublishCapability) &Account) {

        let pp = /public/exampleNFTCollection
        let sp =/storage/exampleNFTCollection

        let col= account.storage.borrow<&ExampleNFT.Collection>(from: sp)
        if col == nil {
            account.storage.save(<- ExampleNFT.createEmptyCollection(), to: sp)
        }

        let cap = account.capabilities.get<&ExampleNFT.Collection>(pp)
        if cap == nil{
            account.capabilities.unpublish(pp)
            let cap = account.capabilities.storage.issue<&ExampleNFT.Collection>(sp)
            account.capabilities.unpublish(pp)
            account.capabilities.publish(cap, at: pp)
        }

        let cap2 = account.capabilities.get<&{NonFungibleToken.Collection}>(pp)
        if cap2 != nil{

            let checked = cap2!.check()
            if checked {
                Debug.log("cap2 checked")
            }else {
                Debug.log("cap2 not checked")
            }
        } else {
            Debug.log("cap2 not found")
        }

        let collection = account.capabilities.borrow<&{NonFungibleToken.Collection}>(pp)! as! &ExampleNFT.Collection

        let cap3 = account.capabilities.get<&{ViewResolver.ResolverCollection}>(pp)
        if cap3 != nil{

            let checked = cap3!.check()
            if checked {

                Debug.log("cap3 checked")
            }else {
                Debug.log("cap3 not checked")
            }
        } else {
            Debug.log("cap3 not found")
        }

        let cap4 = account.capabilities.get<&ExampleNFT.Collection>(pp)
        if cap4 != nil{

            let checked = cap4!.check()
            if checked {

                Debug.log("cap4 checked")
            }else {
                Debug.log("cap4 not checked")
            }
        } else {
            Debug.log("cap4 not found")
        }

    }
}

