all: dev

.PHONY: setup deploy emulator test dev contract contract_publish

setup: deploy
	go run ./tasks/setup/main.go

#this goal deployes all the contracts to emulator
deploy:
	flow project deploy 

emulator:
	flow project start-emulator -v

test:
	gotessum -f testname

dev:
	gotestsum -f testname --watch

contract: 
	npm run prepare && jq '.' lib/find_tmp.json > lib/find.json

publish:
	cd lib && npm publish && cd ..

