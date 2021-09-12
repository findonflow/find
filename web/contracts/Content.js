/** pragma type contract **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  deployContract,
} from 'flow-cadut'

export const CODE = `
  import NonFungibleToken from "./standard/NonFungibleToken.cdc"

//A simple NFT that is used to store a binary data url image on chain
pub contract Content: NonFungibleToken {

    pub var totalSupply: UInt64

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPrivatePath: PrivatePath

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64)

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64

        pub var content: String

        init(initID: UInt64, content: String) {
            self.id = initID
            self.content=content
        }
    }

    //return the content for this NFT
    pub resource interface PublicContent {

        pub fun content(_ id: UInt64): String? 
    }

    pub resource Collection: PublicContent, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an 'UInt64' ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Content.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        pub fun content(_ id: UInt64) : String {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                let nft= ref as! &Content.NFT
                return nft.content
            } 
            panic("Content NFT does not exist")
            
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }


	// mintNFT mints a new NFT with a new ID
    //consider putting this behind a minter
	pub fun createContent(_ content: String) : @Content.NFT {

        var newNFT <- create NFT(initID: Content.totalSupply, content:content)
        emit Created(id: Content.totalSupply)

        Content.totalSupply = Content.totalSupply + UInt64(1)
        return <- newNFT
	}

	init() {
        // Initialize the total supply
        self.totalSupply = 0
        self.CollectionPrivatePath=/private/VersusContentCollection
        self.CollectionStoragePath=/storage/VersusContentCollection
        emit ContractInitialized()
	}
}


`;

/**
* Method to generate cadence code for Content transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const ContentTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `Content =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Deploys Content transaction to the network
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> args - list of arguments
* param Array<string> - list of signers
*/
export const  deployContent = async (props) => {
  const { addressMap = {} } = props;
  const code = await ContentTemplate(addressMap);
  const name = "Content"

  return deployContract({ code, name, ...props })
}