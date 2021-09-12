/** pragma type transaction **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  sendTransaction
} from 'flow-cadut'

export const CODE = `
  
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String) {

    prepare(account: AuthAccount) {


        let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)

        let price=FIND.calculateCost(name)
        log("The cost for registering this name is ".concat(price.toString()))

        let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
        let payVault <- vaultRef.withdraw(amount: price)

        FIND.register(name: name, vault: <- payVault, profile: profileCap)

        log("STATUS POST")
        log(FIND.status(name))

    }

}
 

`;

/**
* Method to generate cadence code for reregister transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const reregisterTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `reregister =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends reregister transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const reregister = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await reregisterTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `reregister =>`);
  reportMissing("signers", signers.length, 1, `reregister =>`);

  return sendTransaction({code, ...props})
}