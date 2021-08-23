# FiNS - Flow identity Name Service

Flow does not have any equivalent to ENS or any way to lookup a user by a tag/alias/nick. 

FiNS is here to solve that issue. 

In order to use FiNS you create your Flow Identity/Profile [and](and) store that in your account. Then you can optionally register that with FiNS for a small yearly fee. 

FiNS is priced with inspiration from ENS. 500 for 3 chars, 100 for 4 chars and 5 for 5 or more chars. 2 and 1 chars can only be minted by admin.

## Flow Identity

Right now an Identity in FiNS is a single user.  It uses the Versus profile to represent a user.


## Plans

 - refactor tests
 - create job to listed to events for JanitorTasks and run janitor on tags affected
 - should registering 1-2 chars really be allowed by admin?

## Testing
 `gotestsum -f testname --watch`
 
 

# Flow Identity and the Flow Identity Network

Right now there is no sentral place of finding some more information about users on Flow. People have to remeber a 16 digit address in order to identify themselves and there is not way to share KYC information, or link profiles together.

Flow Identity Network aim to fix all that.

Flow Identity
 - is a versus profile

Flow Identity Network
 - a Flow Identity can lease an alias in the Network against a small fee in FUSD
  - when a lease run out the alias cannot be claimed until a given freeze period so that the user can release and not risk missing their alias
	
