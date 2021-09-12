/** pragma type transaction **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  sendTransaction
} from 'flow-cadut'

export const CODE = `
  
import FIND from "../contracts/FIND.cdc"

transaction(name: String) {

    prepare(account: AuthAccount) {
       FIND.janitor(name)
    }
}
 

`;

/**
* Method to generate cadence code for janitor transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const janitorTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `janitor =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends janitor transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const janitor = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await janitorTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `janitor =>`);
  reportMissing("signers", signers.length, 1, `janitor =>`);

  return sendTransaction({code, ...props})
}