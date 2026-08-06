using JuMP
using CSV
using DataFrames
const MOI = JuMP.MOI

# Executa a formulação original. Ao término, ela deixa `model`, as variáveis
# de controle e os parâmetros de penalidade disponíveis neste escopo.
include(joinpath(@__DIR__, "(F3)QLIM+VLIM+CSCA.jl"))

const TOLERANCIA_RELATORIO = 1e-8
const TOP_N = 25
const DIRETORIO_ANALISE = joinpath(@__DIR__, "resultados_csv", "analise_F3")
mkpath(DIRETORIO_ANALISE)

identificador(chave) = join(chave.I, ",")

function violacao_restricao(restricao)
    objeto = constraint_object(restricao)
    atividade = value(objeto.func)
    conjunto = objeto.set

    if conjunto isa MOI.EqualTo
        return atividade, abs(atividade - conjunto.value), "igualdade"
    elseif conjunto isa MOI.LessThan
        return atividade, max(0.0, atividade - conjunto.upper), "limite_superior"
    elseif conjunto isa MOI.GreaterThan
        return atividade, max(0.0, conjunto.lower - atividade), "limite_inferior"
    elseif conjunto isa MOI.Interval
        return atividade, max(0.0, conjunto.lower - atividade, atividade - conjunto.upper), "intervalo"
    end

    error("Conjunto de restrição não suportado: $(typeof(conjunto))")
end

function familia_restricao(texto, tipo)
    if occursin("sl_bsh", texto)
        return "CSCA: vínculo de susceptância"
    elseif occursin("sl_v_upp", texto) || occursin("sl_v_low", texto)
        return "VLIM: banda de tensão"
    elseif occursin("sl_v", texto)
        return "QLIM/VLIM: setpoint de tensão"
    elseif occursin("sl_d", texto)
        return "Balanço reativo com slack de carga"
    elseif occursin("cos(", texto) || occursin("sin(", texto)
        return occursin("==", texto) ? "Balanço de potência AC" : "Restrição AC"
    elseif occursin("vm[", texto)
        return "Limite de tensão"
    elseif occursin("pg[", texto) || occursin("qg[", texto)
        return "Limite/fixação de geração"
    end
    return "Outras ($(tipo))"
end

linhas = DataFrame(
    familia=String[], tipo=String[], restricao=String[],
    atividade=Float64[], violacao_pu=Float64[]
)

for (F, S) in list_of_constraint_types(model)
    for restricao in all_constraints(model, F, S)
        atividade, violacao, tipo = violacao_restricao(restricao)
        texto = string(restricao)
        push!(linhas, (
            familia_restricao(texto, tipo), tipo, texto, atividade, violacao
        ))
    end
end

# `list_of_constraint_types` não inclui `@NLconstraint`. Os balanços AC são
# reavaliados abaixo a partir das mesmas expressões que constam na formulação.
for (i, _) in ref[:bus]
    arcos_ac = ref[:bus_arcs][i]
    arcos_dc = ref[:bus_arcs_dc][i]
    geradores = ref[:bus_gens][i]
    cargas = ref[:bus_loads][i]
    shunts = [k for (k, shunt) in ref[:shunt] if shunt["shunt_bus"] == i]

    carga_ativa = sum(load["pd"] for (_, load) in ref[:load] if load["load_bus"] == i; init=0.0)
    carga_reativa = sum(load["qd"] for (_, load) in ref[:load] if load["load_bus"] == i; init=0.0)
    geracao_ativa = sum(value(pg[g]) for g in geradores; init=0.0)
    geracao_reativa = sum(value(qg[g]) for g in geradores; init=0.0)
    fluxo_ativo_dc = sum(value(p_dc[a]) for a in arcos_dc; init=0.0)
    fluxo_reativo_dc = sum(value(q_dc[a]) for a in arcos_dc; init=0.0)
    condutancia_shunt = sum(ref[:shunt][k]["gs"] for k in shunts; init=0.0)
    ajuste_carga = sum(value(sl_d[l]) for l in cargas; init=0.0)
    injecao_shunt = sum(value(bs_var[k]) * value(vm[i])^2 for k in shunts; init=0.0)

    residuo_ativo =
        sum(value(p[a]) for a in arcos_ac; init=0.0) + fluxo_ativo_dc -
        (geracao_ativa - carga_ativa - condutancia_shunt * value(vm[i])^2)
    residuo_reativo =
        sum(value(q[a]) for a in arcos_ac; init=0.0) + fluxo_reativo_dc -
        (geracao_reativa - (carga_reativa + ajuste_carga) + injecao_shunt)

    push!(linhas, ("Balanço ativo AC", "igualdade", "Balanço ativo AC na barra $i",
        residuo_ativo, abs(residuo_ativo)))
    push!(linhas, ("Balanço reativo AC", "igualdade", "Balanço reativo AC na barra $i",
        residuo_reativo, abs(residuo_reativo)))
end

sort!(linhas, :violacao_pu, rev=true)
violadas = filter(:violacao_pu => >(TOLERANCIA_RELATORIO), linhas)
CSV.write(joinpath(DIRETORIO_ANALISE, "restricoes_violadas.csv"), violadas)

resumo_restricoes = if isempty(violadas)
    DataFrame(
        familia=String[], maior_violacao_pu=Float64[],
        soma_violacoes_pu=Float64[], quantidade_violada=Int[]
    )
else
    combine(
        groupby(violadas, :familia),
        :violacao_pu => maximum => :maior_violacao_pu,
        :violacao_pu => sum => :soma_violacoes_pu,
        nrow => :quantidade_violada
    )
end
sort!(resumo_restricoes, :maior_violacao_pu, rev=true)
CSV.write(joinpath(DIRETORIO_ANALISE, "resumo_restricoes_violadas.csv"), resumo_restricoes)

slacks = DataFrame(
    familia=String[], elemento=String[], desvio_pu=Float64[],
    contribuicao_objetivo=Float64[]
)

for i in keys(sl_v)
    desvio = value(sl_v[i])
    push!(slacks, ("QLIM/VLIM: setpoint de tensão", "barra $(identificador(i))", desvio,
        PENALIDADE * desvio^2))
end
for i in keys(sl_v_upp)
    superior = value(sl_v_upp[i])
    inferior = value(sl_v_low[i])
    push!(slacks, ("VLIM: violação superior de tensão", "barra $(identificador(i))", superior,
        PENALIDADE * superior^2))
    push!(slacks, ("VLIM: violação inferior de tensão", "barra $(identificador(i))", inferior,
        PENALIDADE * inferior^2))
end
for i in keys(sl_d)
    desvio = value(sl_d[i])
    push!(slacks, ("Balanço reativo: ajuste de carga", "carga $(identificador(i))", desvio,
        PENALIDADE * desvio^2))
end
for i in keys(sl_bsh)
    desvio = value(sl_bsh[i])
    push!(slacks, ("CSCA: ajuste de susceptância", "shunt $(identificador(i))", desvio,
        PENALIDADE_MENOR * desvio^2))
end

sort!(slacks, :contribuicao_objetivo, rev=true)
slacks_ativos = filter(:contribuicao_objetivo => >(TOLERANCIA_RELATORIO), slacks)
CSV.write(joinpath(DIRETORIO_ANALISE, "slacks_de_controle.csv"), slacks_ativos)

resumo_slacks = if isempty(slacks_ativos)
    DataFrame(
        familia=String[], contribuicao_objetivo=Float64[],
        soma_desvios_absolutos_pu=Float64[], quantidade_ativa=Int[]
    )
else
    combine(
        groupby(slacks_ativos, :familia),
        :contribuicao_objetivo => sum => :contribuicao_objetivo,
        :desvio_pu => (x -> sum(abs, x)) => :soma_desvios_absolutos_pu,
        nrow => :quantidade_ativa
    )
end
sort!(resumo_slacks, :contribuicao_objetivo, rev=true)
CSV.write(joinpath(DIRETORIO_ANALISE, "resumo_slacks_de_controle.csv"), resumo_slacks)

println("\n--- DIAGNÓSTICO DE INVIABILIDADE ---")
println("Status: ", termination_status(model))
println("Restrições violadas acima de $TOLERANCIA_RELATORIO pu: ", nrow(violadas))
println("Maior violação primal (pu): ", isempty(violadas) ? 0.0 : first(violadas.violacao_pu))
println("\nRestrições que mais contribuem para a inviabilidade primal:")
show(first(violadas, min(TOP_N, nrow(violadas))); allcols=true, truncate=100)
println("\n\nResumo por família:")
show(resumo_restricoes; allcols=true)

println("\n\n--- DIAGNÓSTICO DAS FOLGAS DE CONTROLE ---")
println("Objetivo reportado: ", objective_value(model))
println("Soma recomposta das contribuições: ", sum(slacks.contribuicao_objetivo))
println("\nControles que mais contribuem para o objetivo:")
show(first(slacks_ativos, min(TOP_N, nrow(slacks_ativos))); allcols=true, truncate=100)
println("\n\nResumo por família:")
show(resumo_slacks; allcols=true)
println("\n\nCSVs de diagnóstico gravados em $DIRETORIO_ANALISE")
