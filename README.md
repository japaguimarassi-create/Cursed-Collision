# STEAL AN ANIMAL — reconstrução total

Projeto Roblox mobile-first inspirado no estilo visual e no ciclo de progressão de jogos como **Steal An Egg**. O cenário e os modelos são construídos com peças Roblox autorais; screenshots externos são usados somente para pesquisa visual, sem copiar assets.

## Mapa reconstruído

- Corredor principal comprido, caminho central destacado, bordas luminosas e paredes laterais altas para manter orientação.
- Oito zonas sequenciais com paletas e marcos diferentes, mantendo a progressão existente compatível.
- Ninhos visuais em cada zona, com três ovos decorativos de alto contraste e letreiros.
- Oito fazendas em grade 4×2 no hub, com cercas de madeira em dois níveis, abertura de entrada, celeiro, seis slots e esteira.
- Guardiões grandes, animais e decoração colocados fora do eixo principal para que o percurso continue legível.
- Prévia estática do Workspace inclui a geometria do mapa, cercas, ovos e paredes; o servidor constrói a cena jogável separadamente e só remove a prévia após o sucesso.

## Sistemas mantidos e revisados

- Perfis persistentes com sessão bloqueada, autosave e renda offline limitada.
- Roubo de animais bebês, transporte até a fazenda, fuga dos guardiões, depósito, evolução e renda passiva.
- Oito fazendas, 29 espécies, esteiras animadas, treino autoritativo no servidor e melhorias compradas com moedas do jogo.
- Renascimento validado pelo servidor, com 100.000 moedas e velocidade máxima, até 25 vezes; concede +10% de renda permanente por renascimento e preserva animais, banco e nível da esteira.
- Recompensas diárias, quatro missões, três códigos de uso único, estatísticas e MapBot.
- HUD móvel com cartões de recursos, objetivo contextual, ações principais e painéis roláveis; paleta atualizada com contraste mais forte.
- Arquivos de configuração dos passes preservados sem alterações. Esta reconstrução não altera IDs, nomes nem preços desses arquivos.

## Pesquisa visual

Ver [docs/STEAL_AN_EGG_MAP_RESEARCH_2026-10-20.md](docs/STEAL_AN_EGG_MAP_RESEARCH_2026-10-20.md). As capturas analisadas destacam chão verde aberto, cercados retangulares, ovos visíveis, guardiões gigantes, uma rota comprida e interface de alto contraste.

## Salvamentos

Ver [docs/SAVE_MANIFEST_2026-10-20.md](docs/SAVE_MANIFEST_2026-10-20.md). Antes da substituição da branch principal, os estados anteriores foram preservados em branches de backup.

## Validação

```bash
python3 tools/validate_roube_animal.py
luau tools/tests/run.luau
python3 tools/tests/test_map_layout.py
python3 tools/tests/test_monetization.py
python3 tools/tests/test_core_reliability.py
rojo build default.project.json --output build/StealAnAnimal.rbxl
python3 tools/tests/test_rbxl_file.py build/StealAnAnimal.rbxl
```

O pipeline testa sintaxe Luau, regras, arquitetura, mapa, build Rojo e estrutura binária RBXL. Uma build verde não equivale a um playtest no Roblox Studio. Publicação no Roblox continua sendo uma ação manual com confirmação explícita.
