all: dev

.PHONY: setup deploy emulator test dev contract contract_publish client lint

setup: deploy
	go run ./tasks/setup/main.go

lint:
	golangci-lint run 

#this goal deployes all the contracts to emulator
deploy:
	flow project deploy 

emulator:
	flow project start-emulator -v

test:
	gotessum -f testname

dev:
	gotestsum -f testname --watch

client: 
	go run overflow/main.go > lib/find.json

publish:
	cd lib && npm publish && cd ..

patch:
	json-bump lib/package.json --patch

minor:
	json-bump lib/package.json --minor

major:
	json-bump lib/package.json --major
