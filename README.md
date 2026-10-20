# STEAL AN ANIMAL

Projeto Roblox mobile-first com oito biomas, fazendas, animais evolutivos, guardiões, renda passiva e HUD adaptativa. O visual usa modelos e peças originais; as referências de *Steal An Egg* são usadas para orientar composição e ritmo de jogo, não para copiar recursos proprietários.

## Sistemas de jogo

- Corredor de captura com oito biomas, ninhos e ovos decorativos.
- Oito fazendas em grade 4×2, seis espaços por celeiro e esteiras com melhorias.
- 29 espécies, quatro estágios de evolução, renda passiva e renda offline limitada.
- Captura de filhotes, fuga dos guardiões, depósito e coleta de moedas.
- Renascimento validado no servidor: 100.000 moedas e velocidade máxima; até 25 renascimentos, com +10% de renda permanente por renascimento.
- Recompensas diárias, quatro missões, três códigos de uso único, estatísticas, MapBot e NPCs BotX de observação.
- IDs/configurações dos passes mantidos fora do runtime reconstruído e sem mudanças neste trabalho.

## Arquitetura revisada

- `ReplicatedStorage/Shared/WorldBuilder.lua`: cenário, fazendas, cercas, esteiras e letreiros.
- `ReplicatedStorage/Shared/AnimalFactory.lua`: modelos dos animais, silhuetas específicas e estágios.
- `ServerScriptService/Services/ProfileStore.lua`: sanitização, bloqueio de sessão e persistência.
- `StarterPlayerScripts/InteractionPrompt.lua`: interface compacta de interação e tratamento do pressionar/soltar.
- `ServerScriptService/Main.server.lua`: coordena perfis, progressão, remotes, captura, guardiões, economia e ciclo de vida dos jogadores.
- `ServerScriptService/BotX.server.lua`: NPCs observadores, patrulha e registro da sessão.

## Verificação local

Execute a partir da raiz do repositório:

```bash
python3 tools/validate_roube_animal.py
luau tools/tests/run.luau
python3 tools/tests/test_map_layout.py
python3 tools/tests/test_monetization.py
python3 tools/tests/test_core_reliability.py
python3 tools/tests/test_studio_audit.py
python3 tools/tests/test_botx_npc.py
python3 tools/tests/test_release_safety.py
rojo build default.project.json --output build/StealAnAnimal.rbxl
python3 tools/tests/test_rbxl_file.py build/StealAnAnimal.rbxl
python3 tools/simulate_studio_run.py --report artifacts/studio-run-simulation.json --markdown artifacts/studio-run-simulation.md --place build/StealAnAnimal.rbxl
```

O GitHub Actions executa as verificações de sintaxe Luau, regras, estrutura, mapa, HUD, persistência, bots, monetização, build Rojo, arquivo RBXL e simulação de layout. O relatório fica no artefato `StealAnAnimal-simulated-studio-report`.

**Limite da validação:** a simulação de CI não executa o motor Roblox, física, DataStore real, replicação, ProximityPrompt real nem toque em um aparelho. Antes de publicar, abra o artefato RBXL no Roblox Studio, use o plugin de auditoria descrito em [docs/STUDIO_AUTOMATED_AUDIT.md](docs/STUDIO_AUTOMATED_AUDIT.md), teste com clientes simulados e faça uma sessão de teste no celular. Guarde o SHA do commit testado como `STEAL_ANIMAL_STUDIO_QA_SHA) nas variáveis do repositório. A publicação manual só prossegue se as duas confirmações forem marcadas e essa variável corresponder exatamente ao commit publicado.

## Pesquisa, auditoria e salvamentos

- [Auditoria e reescrita completa de 20/10/2026](docs/FULL_GAME_AUDIT_2026-10-20.md)
- [Pesquisa visual do mapa](docs/STEAL_AN_EGG_MAP_RESEARCH_2026-10-20.md)
- [Pesquisa de HUD mobile](docs/HUD_DESIGN_RESEARCH_2026-10-20.md)
- [Auditoria automatizada no Studio](docs/STUDIO_AUTOMATED_AUDIT.md)
- [Auditoria dos NPCs BotX](docs/BOTX_NPC_AUDIT.md)
- [Manifesto dos backups](docs/SAVE_MANIFEST_2026-10-20.md)

Não há publicação automática após a validação. Publicar é uma operação separada e bloqueada até a aprovação explícita de um teste real do Studio para o mesmo commit.
