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

transaction(clock: UFix64) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!
		adminClient.advanceClock(clock)

	}
}

`;

/**
* Method to generate cadence code for clock transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const clockTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `clock =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends clock transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const clock = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await clockTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `clock =>`);
  reportMissing("signers", signers.length, 1, `clock =>`);

  return sendTransaction({code, ...props})
}