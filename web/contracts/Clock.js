/** pragma type transaction **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  sendTransaction
} from 'flow-cadut'

export const CODE = `
  
/*
A contract to mock time. 

If you want to mock time create an function in your admin that enables the  Clock
The clock will then start at block 0
use the tick method to tick the time. 

'''
		//this is used to mock the clock, NB! Should consider removing this before deploying to mainnet?
		pub fun tickClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot use AdminProxy, ste capability first"
			}
			Clock.enable()
			Clock.tick(time)
		}
'''

You can then call this from a transaction like this:

'''
import YourThing from "../contracts/YouThing.cdc"

transaction(clock: UFix64) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&YourThing.AdminProxy>(from: YourThing.AdminProxyStoragePath)!
		adminClient.tickClock(clock)

	}
}
'''

In order to read the mocked time you use the following code in cadence

'''
Clock.time()
'''

Limitations: 
 - all contracts must live in the same account to (ab)use this trick

*/
pub contract Clock{
	//want to mock time on emulator. 
	access(contract) var fakeClock:UFix64
	access(contract) var enabled:Bool


	access(account) fun tick(_ duration: UFix64) {
		self.fakeClock = self.fakeClock + duration
	}


	access(account) fun enable() {
		self.enabled=true
	}

	//mocking the time! Should probably remove self.fakeClock in mainnet?
	pub fun time() : UFix64 {
		if self.enabled {
			return self.fakeClock 
		}
		return getCurrentBlock().timestamp
	}

	init() {
		self.fakeClock=0.0
		self.enabled=false
	}

}


`;

/**
* Method to generate cadence code for Clock transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const ClockTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `Clock =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends Clock transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const Clock = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await ClockTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `Clock =>`);
  reportMissing("signers", signers.length, 1, `Clock =>`);

  return sendTransaction({code, ...props})
}