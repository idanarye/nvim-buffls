.PHONY: docs

docs:
	mkdir -p doc
	lemmy-help --prefix-func lua/buffls/init.lua | tee doc/buffls.txt
