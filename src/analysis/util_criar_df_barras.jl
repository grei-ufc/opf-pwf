# ========================================================================
# Utilidade: Criar DataFrame de Barras a partir do Dicionário data["bus"]
# ========================================================================
# Descrição: Extrai dados das barras do dicionário 'data' e cria um 
#            DataFrame com as seguintes colunas:
#            index, bus_i, bus_type, name, vmax, vmin, vm, va, base_kv
#
# Uso:
#    1. Certificar que 'data' está carregado (ex: data = PWF.parse_file(...))
#    2. Executar este script ou usar a função criar_df_barras(data)
# ========================================================================

using DataFrames
using CSV

"""
    criar_df_barras(data::Dict; salvar_csv=false, caminho_csv="df_barras.csv")

Cria um DataFrame a partir do dicionário data["bus"] contendo informações das barras.

# Argumentos
- `data::Dict`: Dicionário com dados de potência (contendo "bus")
- `salvar_csv::Bool`: Se true, salva o dataframe como CSV
- `caminho_csv::String`: Caminho do arquivo CSV a ser salvo

# Retorna
- DataFrame com colunas: index, bus_i, bus_type, name, vmax, vmin, vm, va, base_kv

# Exemplo
```julia
using PWF
data = PWF.parse_file("caminho/arquivo.pwf")
df_barras = criar_df_barras(data, salvar_csv=true)
```
"""
function criar_df_barras(data::Dict; salvar_csv=false, caminho_csv="df_barras.csv")
    
    # Inicializar dicionário com as colunas
    df_dict = Dict(
        :index => [],
        :bus_i => [],
        :bus_type => [],
        :name => [],
        :vmax => [],
        :vmin => [],
        :vm => [],
        :va => [],
        :base_kv => []
    )
    
    # Iterar sobre cada barra e preencher os dados
    for (bus_id, bus_dict) in data["bus"]
        push!(df_dict[:index], bus_dict["index"])
        push!(df_dict[:bus_i], bus_dict["bus_i"])
        push!(df_dict[:bus_type], bus_dict["bus_type"])
        push!(df_dict[:name], bus_dict["name"])
        push!(df_dict[:vmax], bus_dict["vmax"])
        push!(df_dict[:vmin], bus_dict["vmin"])
        push!(df_dict[:vm], bus_dict["vm"])
        push!(df_dict[:va], bus_dict["va"])
        push!(df_dict[:base_kv], bus_dict["base_kv"])
    end
    
    # Criar DataFrame
    df_barras = DataFrame(df_dict)
    
    # Salvar como CSV se solicitado
    if salvar_csv
        CSV.write(caminho_csv, df_barras)
        println("✓ DataFrame salvo em: $caminho_csv")
    end
    
    println("✓ DataFrame criado com sucesso!")
    println("  Dimensões: $(nrow(df_barras)) barras × $(ncol(df_barras)) colunas")
    
    return df_barras
end

# Se executado diretamente, criar o dataframe usando 'data' já carregado
if @isdefined data
    global df_barras = criar_df_barras(data, salvar_csv=true)
    println("\nPrimeiras 5 linhas do dataframe:")
    display(first(df_barras, 5))
else
    println("Aviso: 'data' não está definido. Execute este script após carregar os dados.")
end
