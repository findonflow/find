import FUSD from "../standard/FUSD.cdc"  
import NonFungibleToken from "../standard/NonFungibleToken.cdc"  
import FungibleToken from "../standard/FungibleToken.cdc"  
import CoatCheck from "./CoatCheck.cdc"  

pub contract FlowtyUtils {
    access(contract) var Attributes: {String: AnyStruct}

    access(all) let FlowtyUtilsStoragePath: StoragePath

    access(all) resource FlowtyUtilsAdmin {
        // addSupportedTokenType
        // add a supported token type that can be used in Flowty loans
        access(all) addSupportedTokenType(type: Type) {
            var supportedTokens = FlowtyUtils.Attributes["supportedTokens"]
            if supportedTokens == nil {
                supportedTokens = [Type<@FUSD.Vault>()] as! [Type] 
            }

            let tokens = supportedTokens! as! [Type]

            if !FlowtyUtils.isTokenSupported(type: type) {
                tokens.append(type)
            }

            FlowtyUtils.Attributes["supportedTokens"] = tokens
        }
    }

    access(all) getSupportedTokens(): AnyStruct {
        return self.Attributes["supportedTokens"]!
    }

    // getAllowedTokens
    // return an array of types that are able to be used as the payment type
    // for loans
    access(all) getAllowedTokens(): [Type] {
        var supportedTokens = self.Attributes["supportedTokens"]
        return supportedTokens != nil ? supportedTokens! as! [Type] : [Type<@FUSD.Vault>()]
    }

    // isTokenSupported
    // check if the given type is able to be used as payment
    access(all) isTokenSupported(type: Type): Bool {
        for t in FlowtyUtils.getAllowedTokens() {
            if t == type {
                return true
            }
        }

        return false
    }

    access(account) fun trySendFungibleTokenVault(vault: @FungibleToken.Vault, receiver: Capability<&{FungibleToken.Receiver}>){
        let redeemer = receiver.address
        if !receiver.check() {
            let valet = CoatCheck.getValet()
            let vaults: @[FungibleToken.Vault] <- []
            vaults.append(<-vault)
            valet.createTicket(redeemer: redeemer, vaults: <-vaults, tokens: nil)
        } else {
            receiver.borrow()!.deposit(from: <-vault)
        }
    }

    access(account) fun trySendNFT(nft: @NonFungibleToken.NFT, receiver: Capability<&{NonFungibleToken.Collection}>) {
        let redeemer = receiver.address
        if !receiver.check() {
            let valet = CoatCheck.getValet()
            let nfts: @[NonFungibleToken.NFT] <- []
            nfts.append(<-nft)
            valet.createTicket(redeemer: redeemer, vaults: nil, tokens: <-nfts)
        } else {
            receiver.borrow()!.deposit(token: <-nft)
        }
    }


    init() {
        self.Attributes = {}

        self.FlowtyUtilsStoragePath = /storage/FlowtyUtils

        let utilsAdmin <- create FlowtyUtilsAdmin()
        self.account.storage.save(<-utilsAdmin, to: self.FlowtyUtilsStoragePath)
    }
}
