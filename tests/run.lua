package.path = table.concat({
    "./lua/?.lua",
    "./lua/?/init.lua",
    "./tests/?.lua",
    package.path,
}, ";")

local specs = {
    "tests.scretch_spec",
}

local failures = 0

for _, spec in ipairs(specs) do
    package.loaded[spec] = nil
    local ok, err = pcall(require, spec)
    if not ok then
        io.stderr:write(("FAILED %s\n%s\n"):format(spec, err))
        failures = failures + 1
    else
        io.stdout:write(("OK %s\n"):format(spec))
    end
end

if failures > 0 then
    os.exit(1)
end
