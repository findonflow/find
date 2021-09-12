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
        let status=FIND.status(name)
				if status.status == FIND.LeaseStatus.LOCKED {
					panic("locked")
				}
				if status.status == FIND.LeaseStatus.FREE {
					panic("free")
				}
    }

}
 

`;

/**
* Method to generate cadence code for status transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const statusTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `status =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends status transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const status = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await statusTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `status =>`);
  reportMissing("signers", signers.length, 1, `status =>`);

  return sendTransaction({code, ...props})
}