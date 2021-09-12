/** pragma type transaction **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  sendTransaction
} from 'flow-cadut'

export const CODE = `
  
import "../contracts/FIND.cdc"

//set up the adminClient in the contract that will own the network
transaction() {

    prepare(account: AuthAccount) {

        account.save(<- FIND.createAdminProxyClient(), to:FIND.AdminProxyStoragePath)
        account.link<&{FIND.AdminProxyClient}>(FIND.AdminProxyPublicPath, target: FIND.AdminProxyStoragePath)


    }
}

`;

/**
* Method to generate cadence code for setupFin1CreateClient transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const setupFin1CreateClientTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `setupFin1CreateClient =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends setupFin1CreateClient transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const setupFin1CreateClient = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await setupFin1CreateClientTemplate(addressMap);

  reportMissing("arguments", args.length, 0, `setupFin1CreateClient =>`);
  reportMissing("signers", signers.length, 1, `setupFin1CreateClient =>`);

  return sendTransaction({code, ...props})
}