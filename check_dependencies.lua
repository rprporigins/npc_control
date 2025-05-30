-- Verificador de Dependências
local dependencies = {
    {name = "qb-core", required = true},
    {name = "ox_lib", required = true},
    {name = "ox_target", required = false},
    {name = "oxmysql", required = false}
}

print("^3=== Gang NPC Manager - Verificação de Dependências ===^7")
local missing = {}
local optional_missing = {}

for _, dep in ipairs(dependencies) do
    if GetResourceState(dep.name) == "started" then
        print("^2✓ " .. dep.name .. " - OK^7")
    else
        if dep.required then
            table.insert(missing, dep.name)
            print("^1✗ " .. dep.name .. " - FALTANDO (OBRIGATÓRIO)^7")
        else
            table.insert(optional_missing, dep.name)
            print("^3✗ " .. dep.name .. " - FALTANDO (OPCIONAL)^7")
        end
    end
end

print("")

if #missing > 0 then
    print("^1ERRO: Dependências obrigatórias faltando: " .. table.concat(missing, ", "))
    print("Por favor, instale as dependências antes de iniciar o resource.^7")
else
    print("^2✓ Todas as dependências obrigatórias estão instaladas!^7")
end

if #optional_missing > 0 then
    print("^3Aviso: Dependências opcionais faltando: " .. table.concat(optional_missing, ", "))
    print("O resource funcionará, mas com funcionalidades limitadas.^7")
end

print("^3=================================================^7")
