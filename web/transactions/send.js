/** pragma type transaction **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  sendTransaction
} from 'flow-cadut'

export const CODE = `
  import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

    prepare(account: AuthAccount) {
        let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")

        log("Sending ".concat(amount.toString()).concat( " to profile with name ").concat(name))
        FIND.deposit(to: name, from: <- vaultRef.withdraw(amount: amount))
    }

}
 

`;

/**
* Method to generate cadence code for send transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const sendTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `send =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends send transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const send = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await sendTemplate(addressMap);

  reportMissing("arguments", args.length, 2, `send =>`);
  reportMissing("signers", signers.length, 1, `send =>`);

  return sendTransaction({code, ...props})
}