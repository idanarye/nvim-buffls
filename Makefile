.PHONY: docs test

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"


docs:
	mkdir -p doc
	lemmy-help --prefix-func lua/buffls/{init,_just_for_documentation,QueryRouter,TsLs,TsQueryRouter,TsQueryHandlerContext,ForBash,LineList}.lua | tee doc/buffls.txt
