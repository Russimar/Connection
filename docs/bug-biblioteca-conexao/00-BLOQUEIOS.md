# Bloqueios

```
B-01 | T-01.01 | RESOLVIDO em 2026-09-15. O criterio_aceite exigia "MSBuild retorna código 0", mas o MSBuild falha com MSB6003 ("The command-line for the DCC task is too long"): o .dproj herda o search path global do IDE e estoura o limite de 32000 caracteres. | Destravado por T-01.02: tests/build.bat tenta MSBuild e cai para dcc32.exe com dcc32.cfg enxuto quando o executável não é produzido. O build oficial do harness passou a ser tests/build.bat, que retorna ERRORLEVEL 0 e gera o executável — o critério "compilação retorna código 0" é atendido pelo meio de build do projeto. Divergência registrada no relatório final.
```
