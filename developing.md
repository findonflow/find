# Developing .find

.find uses some of the tools that I (bjartek) have made to develop and test cadence code. 

 -  [overflow](https://github.com/bjartek/overflow) is beeing used for testing and running manual `storylines`

This repo is the backend code, there are two other repos in this solutions namely
 - [find-lookup](https://github.com/findonflow/find-lookup) a serverless function to lookup names from web2
 - [find-web](https://github.com/findonflow/find-web) the frontend code
 

## Tests
In order to run the tests for .find we recommend using (gotestsum)[https://github.com/gotestyourself/gotestsum] with the following invocation

```
gotestsum -f testname --hide-summary output
```

## Storylines
There are also some tasks or storylines that you might want to run/modify if you want to experiment with how .find works

Take a look in the tasks folder and run a task with the form
```
go run tasks/demo/main.go
```

## Integrating between frontend and backend
.find uses a feature in [overflow](https://github.com/bjartek/overflow) to convert the transactions/scripts in this repo into a json file that is then published to npm.

This flow will be integrated into CI but right now it works like this

 - `make client` will run the logic to generate the file lib/find.json
 - `make minor|patch|major` will bump the semantic version of the lib/package.json file
 - `make publish` will publish this file to NPM

In the frontend code this module is then used as an [NPM import](https://github.com/findonflow/find-web/blob/master/src/functions/txfunctions.js#L3) and used with FCL in a transaction [like this](https://github.com/findonflow/find-web/blob/master/src/functions/txfunctions.js#L13)

We are planning to look at flow-cadut in the future
