.PHONY: docs test

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"


docs:
	mkdir -p doc
	lemmy-help --prefix-func lua/buffls/init.lua | tee doc/buffls.txt
