
# Dados de Convergência

Dados do Sover Ipopt para convergência do OPF via PWF/PowerModels: 

```txt
iter    objective    inf_pr   inf_du lg(mu)  ||d||  lg(rg) alpha_du alpha_pr  ls
 490  1.0248527e-01 1.06e-01 2.22e-05  -5.0 2.47e+00  -6.2 1.00e+00 1.00e+00h  1
 491  1.0247554e-01 2.23e-02 1.95e-06  -5.0 1.19e+00  -5.8 1.00e+00 1.00e+00h  1
 492  1.0246209e-01 4.16e-02 2.63e-06  -5.0 3.00e+00  -6.3 1.00e+00 1.00e+00h  1
 493  1.0246223e-01 4.40e-03 1.40e-06  -5.0 9.63e-01  -5.8 1.00e+00 1.00e+00h  1
 494  1.0245834e-01 3.10e-02 3.59e-06  -5.0 2.58e+00  -6.3 1.00e+00 1.00e+00h  1
 495  1.0245666e-01 3.41e-03 1.09e-06  -5.0 8.43e-01  -5.9 1.00e+00 1.00e+00h  1
 496  1.0245326e-01 1.99e-02 2.57e-06  -5.0 2.05e+00  -6.4 1.00e+00 1.00e+00h  1
 497  1.0245214e-01 2.02e-03 7.45e-07  -5.0 6.46e-01  -5.9 1.00e+00 1.00e+00h  1
 498  1.0244942e-01 1.04e-02 1.40e-05  -5.0 1.47e+00  -6.4 1.00e+00 1.00e+00h  1
 499  1.0244908e-01 9.86e-04 4.62e-07  -5.0 4.50e-01  -6.0 1.00e+00 1.00e+00h  1
iter    objective    inf_pr   inf_du lg(mu)  ||d||  lg(rg) alpha_du alpha_pr  ls
 500  1.0244903e-01 1.85e-05 4.51e-07  -5.0 6.19e-02  -5.1 1.00e+00 1.00e+00h  1

Number of Iterations....: 500

                                   (scaled)                 (unscaled)
Objective...............:   1.0244902602385769e-01    1.0244902602385769e-01
Dual infeasibility......:   4.5072344154241146e-07    4.5072344154241146e-07
Constraint violation....:   1.4315067782266766e-05    1.8519483411694182e-05
Variable bound violation:   0.0000000000000000e+00    0.0000000000000000e+00
Complementarity.........:   9.0909090909179425e-06    9.0909090909179425e-06
Overall NLP error.......:   1.4315067782266766e-05    1.8519483411694182e-05


Number of objective function evaluations             = 503
Number of objective gradient evaluations             = 501
Number of equality constraint evaluations            = 503
Number of inequality constraint evaluations          = 503
Number of equality constraint Jacobian evaluations   = 501
Number of inequality constraint Jacobian evaluations = 501
Number of Lagrangian Hessian evaluations             = 500
Total seconds in IPOPT                               = 401.025

EXIT: Optimal Solution Found.

--- ESTATÍSTICAS DE RESOLUÇÃO ---
Status da Convergência: LOCALLY_SOLVED
Tempo interno do Solver (Ipopt): 404.6527 segundos
Tempo total da execução da função: 406.4367 segundos
Erro de Controle (Slacks Ponderadas): 0.10244902602385769

--- RESUMO OPERACIONAL GLOBAL ---
Tensão Mínima (pu):         0.8229
Tensão Máxima (pu):         1.1
Geração Ativa Total (pu):   920.6675
Geração Reativa Total (pu): -20.578
Perdas Ativas (Total pu):   45.4972

--- RESUMO EM UNIDADES REAIS (Base = 100.0 MVA) ---
Geração Ativa Total (MW):   92066.75
Geração Reativa Total (MVAr):-2057.8
Perdas Ativas Totais (MW):  4549.72
```
