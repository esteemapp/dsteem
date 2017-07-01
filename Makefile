
SHELL := /bin/bash
PATH  := ./node_modules/.bin:$(PATH)

SRC_FILES := $(wildcard src/*.ts)

lib: $(SRC_FILES) node_modules
	tsc -p tsconfig.json --outDir lib
	touch lib

.PHONY: bundle
bundle: lib
	browserify src/index-browser.ts --debug \
		--standalone Client --plugin tsify \
		--transform [ babelify --extensions .ts ] \
		| derequire > dist/dsteem.js
	uglifyjs dist/dsteem.js \
		--source-map "content=inline,url=dsteem.js.map,filename=dist/dsteem.js.map" \
		--compress "dead_code,collapse_vars,reduce_vars,keep_infinity,drop_console,passes=2" \
		--output dist/dsteem.js
	gzip --best --keep --force dist/dsteem.js

.PHONY: coverage
coverage: node_modules
	nyc -r html -r text -e .ts -i ts-node/register mocha --reporter nyan --require ts-node/register test/*.ts

.PHONY: test
test: node_modules
	mocha --require ts-node/register test/*.ts

.PHONY: ci-test
ci-test: node_modules
	tslint -p tsconfig.json -c tslint.json
	nyc -r lcov -e .ts -i ts-node/register mocha --reporter tap --require ts-node/register test/*.ts

.PHONY: lint
lint: node_modules
	tslint -p tsconfig.json -c tslint.json -t stylish --fix

node_modules:
	npm install

.PHONY: docs
docs: node_modules
	typedoc --gitRevision master --target ES6 --mode file --out docs src
	find docs -name "*.html" | xargs sed -i '' 's~$(shell pwd)~.~g'
	echo "Served at <https://jnordberg.github.io/dsteem/>" > docs/README.md

.PHONY: clean
clean:
	rm -rf lib/

.PHONY: distclean
distclean: clean
	rm -rf node_modules/