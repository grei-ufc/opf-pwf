# Relatório de Análise — F3 QLIM + VLIM + CSCA

## Configuração avaliada

O modelo `(F3)QLIM+VLIM+CSCA.jl` foi executado por
`analisar_F3_QLIM_VLIM_CSCA.jl` na versão atual da formulação.

- As barras de referência do PWF são preservadas: `7051`, `501`, `1100`,
  `8004` e `1040`.
- Apenas a primeira referência, barra `7051`, tem `va` fixado em `0,0`.
- O bloco que fixava `pg` dos geradores fora das barras de referência está
  comentado. Assim, **todos os geradores** podem variar dentro de seus limites
  `pmin` e `pmax`, e não apenas os geradores das barras de referência.
- O PowerModels emitiu o aviso de que múltiplas barras de referência na mesma
  componente conectada podem causar inviabilidade.

## Execução

| Métrica                           | Resultado |
| :-------------------------------- | --------: |
| Solver                            |     Ipopt |
| Status                            | `LOCALLY_INFEASIBLE` |
| Iterações                         |        46 |
| Tempo interno do solver           | 25,46 s |
| Tempo total da execução           | 26,55 s |
| Objetivo (folgas ponderadas)      | 415,098250 |
| Inviabilidade primal máxima       | 1,670855 pu |
| Inviabilidade dual                | 10,206913 |
| Violação de limites de variáveis  | 9,09e-10 pu |

O Ipopt encerrou em um ponto localmente inviável após apenas 46 iterações.
Logo, a execução não produziu uma solução ótima local viável, nem oferece
garantia de ótimo global. O erro dual de `10,206913` também demonstra que as
condições de estacionariedade não foram satisfeitas.

## Violações de restrições físicas

| Restrição        | Barra | Residual (pu) | Equivalente na base de 100 MVA |
| :--------------- | ----: | ------------: | ------------------------------: |
| Balanço ativo AC |  8004 |  -1,670855256 |                  -167,08553 MW |
| Balanço ativo AC |  8583 |   1,433421e-4 |                     0,014334 MW |
| Balanço ativo AC |  8540 |   1,333931e-4 |                     0,013339 MW |
| Balanço ativo AC |  8587 |   4,810160e-5 |                     0,004810 MW |
| Balanço ativo AC |  8591 |   3,764409e-5 |                     0,003764 MW |
| Balanço ativo AC |  3827 |   1,954510e-5 |                     0,001955 MW |
| Balanço ativo AC |  8584 |   1,936657e-5 |                     0,001937 MW |

Foram identificadas **3.249** restrições acima da tolerância de relatório
(`1e-8 pu`): 1.870 balanços ativos e 1.379 balanços reativos. A soma dos
resíduos absolutos foi `1,67285 pu` para os balanços ativos e `9,75335e-5 pu`
para os reativos.

O balanço ativo na barra `8004` é o problema dominante, com residual de
`-1,670855 pu` (`-167,09 MW`). Ele responde praticamente por toda a
inviabilidade primal e é várias ordens de grandeza maior que os demais
resíduos. Em comparação com a execução anterior, cujo maior resíduo era
`-8,552567e-4 pu` na mesma barra, a violação aumentou cerca de 1.954 vezes.

## Controles que mais contribuem para o objetivo

| Família de controle              | Contribuição ao objetivo | Participação aproximada |
| :-------------------------------- | -----------------------: | -----------------------: |
| VLIM: violação inferior de tensão |               173,573103 |                    41,8% |
| VLIM: violação superior de tensão |               160,000129 |                    38,5% |
| Ajuste de carga reativa           |                76,757375 |                    18,5% |
| CSCA: ajuste de susceptância      |                 4,758990 |                     1,1% |
| QLIM/VLIM: desvio de setpoint     |                 0,008654 |                     0,0% |

| Controle                         | Elemento    | Desvio (pu) | Contribuição ao objetivo |
| :------------------------------- | :---------- | ----------: | -----------------------: |
| Ajuste de carga reativa          | Carga 8458  |   +0,510406 |                 2,605142 |
| Ajuste de carga reativa          | Carga 4989  |   +0,356622 |                 1,271793 |
| Ajuste de carga reativa          | Carga 7844  |   +0,298528 |                 0,891192 |
| Ajuste de carga reativa          | Carga 3185  |   +0,298528 |                 0,891192 |
| Ajuste de carga reativa          | Carga 3304  |   +0,258900 |                 0,670291 |
| Ajuste de carga reativa          | Carga 8490  |   +0,235362 |                 0,553952 |
| Ajuste de carga reativa          | Carga 11547 |   +0,231088 |                 0,534017 |
| Ajuste de carga reativa          | Carga 11939 |   +0,204389 |                 0,417749 |
| VLIM: violação inferior de tensão| Barra 7051  |   +0,177807 |                 0,316152 |

As violações VLIM representam aproximadamente 80,3% do objetivo. Há 1.751
folgas ativas em cada sentido da faixa de tensão, com desvios absolutos totais
de `173,876868 pu` abaixo do limite e `167,192206 pu` acima do limite. Esses
números revelam que as faixas de tensão impostas não são atendidas de forma
generalizada no ponto retornado.

## Comparação com a execução anterior

| Métrica                     | Execução anterior | Execução atual |
| :-------------------------- | ----------------: | -------------: |
| Status                      | `LOCALLY_INFEASIBLE` | `LOCALLY_INFEASIBLE` |
| Iterações                   |               456 |             46 |
| Tempo interno               |          365,42 s |        25,46 s |
| Objetivo                    |         78,885235 |      415,098250 |
| Inviabilidade primal máxima |      8,552567e-4  |     1,670855 |
| Inviabilidade dual          |         35,520031 |    10,206913 |
| Resíduo ativo na barra 8004 |     -8,552567e-4  |    -1,670855 |

A formulação atual encontra mais rapidamente um ponto inviável, mas a
factibilidade primal e o objetivo pioraram de forma substancial. A redução da
inviabilidade dual não compensa o aumento extremo do resíduo no balanço ativo
da barra `8004`.

## Recomendações para facilitar a convergência

1. Restaurar a lógica que fixa `pg` dos geradores que não pertencem às barras
   de referência, caso essa não tenha sido uma alteração intencional. A versão
   atual deixou todos os geradores livres, o que mudou o problema além da
   regra originalmente desejada.
2. Investigar prioritariamente a barra `8004`, seus geradores, cargas, ramos
   AC e elos DC conectados. Seu desequilíbrio de `167,09 MW` é a causa
   determinante da inviabilidade.
3. Validar se as cinco barras de referência pertencem à mesma ilha e se devem
   ser tratadas simultaneamente como referências. O aviso do PowerModels
   aponta esse arranjo como possível origem de inviabilidade.
4. Inicializar `vm` e `va` pelos valores do PWF e aplicar os limites
   individuais `vmin` e `vmax`; a formulação ainda usa `vm = 1,0`, `va = 0,0`
   e limites globais de `0,8` a `1,1 pu`.
5. Usar uma solução de fluxo de potência AC como *warm start* e introduzir
   QLIM, VLIM e CSCA gradualmente, por continuação/homotopia.
6. Revisar a escala das penalidades e as faixas VLIM: as violações de tensão
   dominam o objetivo e estão distribuídas por todas as 1.751 barras
   controladas em cada direção.
7. Não relaxar a tolerância do Ipopt como medida corretiva: isso ocultaria uma
   violação ativa de grande porte sem resolver sua causa física ou de
   formulação.

## Script de diagnóstico

O script `analisar_F3_QLIM_VLIM_CSCA.jl` reproduz esta análise e grava os CSVs
de violações e contribuições em `resultados_csv/analise_F3/`.

```bash
julia --project=. analisar_F3_QLIM_VLIM_CSCA.jl
```
