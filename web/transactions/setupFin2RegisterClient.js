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


//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{FIND.AdminProxyClient}>(FIND.AdminProxyPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let network=account.getCapability<&FIND.Network>(FIND.NetworkPrivatePath)
        client.addCapability(network)

    }
}
 

`;

/**
* Method to generate cadence code for setupFin2RegisterClient transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const setupFin2RegisterClientTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `setupFin2RegisterClient =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends setupFin2RegisterClient transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const setupFin2RegisterClient = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await setupFin2RegisterClientTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `setupFin2RegisterClient =>`);
  reportMissing("signers", signers.length, 1, `setupFin2RegisterClient =>`);

  return sendTransaction({code, ...props})
}