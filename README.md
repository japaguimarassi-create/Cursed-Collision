# STEAL AN ANIMAL — reconstrução total

Projeto Roblox mobile-first inspirado no estilo visual de **Steal An Egg**. O mapa e os modelos usam peças Roblox autorais; imagens externas servem apenas para pesquisa e análise visual.

## Mapa

- Corredor principal longo com caminho central, bordas luminosas e paredes laterais.
- Oito biomas sequenciais, com paletas, marcos e paisagismo diferentes.
- Ninhos em cada bioma, com três ovos decorativos de alto contraste.
- Oito fazendas em grade 4×2, cercas de madeira em dois níveis e abertura de entrada.
- Guardiões grandes e decoração fora do eixo principal para manter o caminho legível.
- Prévia estática do Workspace inclui paredes, cercas, ninhos e ovos; o servidor constrói a cena jogável separadamente.

## Sistemas

- Perfis persistentes com bloqueio de sessão, autosave e renda offline limitada.
- Roubo de animais bebês, fuga dos guardiões, depósito, evolução e renda passiva.
- 29 espécies, seis espaços por fazenda, esteiras animadas e melhorias com moedas do jogo.
- Renascimento validado no servidor: 100.000 moedas e velocidade máxima; até 25 renascimentos, +10% de renda permanente por renascimento, preservando animais, banco e esteira.
- Recompensas diárias, quatro missões, três códigos de uso único, estatísticas e MapBot.
- HUD móvel com recursos, objetivo contextual, ações principais e painéis; paleta atualizada para maior contraste.
- Configurações dos passes preservadas sem alterar IDs, nomes ou preços.

## Pesquisa e salvamentos

- [Pesquisa visual de Steal An Egg e especificação do mapa](docs/STEAL_AN_EGG_MAP_RESEARCH_2026-10-20.md)
- [Pesquisa e especificação do HUD mobile](docs/HUD_DESIGN_RESEARCH_2026-10-20.md)
- [Bots de QA do Roblox Studio e relatórios automatizados](docs/STUDIO_AUTOMATED_AUDIT.md)
- [Simulador de execução e relatório JSON](tools/simulate_studio_run.py)
- [Manifesto dos backups e estados salvos](docs/SAVE_MANIFEST_2026-10-20.md)

## Validação

```bash
python3 tools/validate_roube_animal.py
luau tools/tests/run.luau
python3 tools/tests/test_map_layout.py
python3 tools/tests/test_monetization.py
python3 tools/tests/test_core_reliability.py
python3 tools/tests/test_studio_audit.py
rojo build default.project.json --output build/StealAnAnimal.rbxl
python3 tools/simulate_studio_run.py --report artifacts/studio-run-simulation.json --markdown artifacts/studio-run-simulation.md --place build/StealAnAnimal.rbxl
rojo build default.project.json --output build/StealAnAnimal.rbxl
python3 tools/tests/test_rbxl_file.py build/StealAnAnimal.rbxl
```

A CI valida sintaxe, regras, mapa, bots de QA, build Rojo, estrutura binária RBXL e simulação determinística do HUD. O relatório JSON/Markdown fica no artefato `StealAnAnimal-simulated-studio-report`. Essa simulação não se apresenta como execução real do Studio; para o teste de engine com clientes simulados, use o plugin descrito em `docs/STUDIO_AUTOMATED_AUDIT.md`. A publicação continua manual e exige confirmação explícita.
