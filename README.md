# STEAL AN ANIMAL

Projeto Roblox mobile-first com oito biomas, fazendas, animais evolutivos, guardiões, renda passiva e HUD adaptativa. O visual usa modelos e peças originais; as referências de *Steal An Egg* são usadas para orientar composição e ritmo de jogo, não para copiar recursos proprietários.

## Direção visual original — 03/11/2026

O visual de Steal An Animal é próprio. Referências de outros jogos são usadas somente para estudar composição, escala, legibilidade e progressão, sem copiar construções, animais, interface ou layouts. A revisão geométrica substitui estruturas fechadas por marcos esculturais abertos, volumes facetados, WedgeParts, anéis poligonais e formas próprias por bioma. Consulte [a direção visual original](docs/3d/ORIGINAL_VISUAL_DIRECTION_2026-11-03.md).

## Sistemas de jogo

- Identidade própria de Steal An Animal: safe zone aberta, oito fazendas, uma única pista reta e oito biomas em sequência. Cada bioma tem requisito mínimo de SPEED para roubar animais: 10, 100, 1.230, 12.300, 123.000, 1.230.000, 12.300.000 e 123.000.000. O percurso permanece aberto; o servidor valida a fase no momento da captura e limita a velocidade física para preservar o controle mobile.
- Oito fazendas em grade 4×2, seis espaços por celeiro e esteiras com melhorias.
- 49 espécies, cada uma com detalhes anatômicos específicos, quatro estágios de evolução, renda passiva e renda offline limitada; oito espécies de destaque recebem anatomia em camadas, padrões de superfície, cristais de vidro, peças emissivas, filigranas, penas sobrepostas, carapaças segmentadas, galhadas ramificadas, folhagem, caudas múltiplas e juba radial.
- Sistema visual por raridade: halo geométrico nos pets Míticos ou superiores em estágios avançados; partículas e luz local apenas nos níveis Secreto, Eterno e Divino. Os adornos de raridade não são aplicados aos filhotes comuns.
- Captura de filhotes, fuga dos guardiões, depósito e coleta de moedas.
- Renascimento validado no servidor: 100.000 moedas e velocidade máxima; até 25 renascimentos, com +10% de renda permanente por renascimento.
- Recompensas diárias, quatro missões, três códigos de uso único e estatísticas. Não existem NPCs-bot; os oito guardiões permanecem com IA pausada até um roubo validado no próprio bioma.
- IDs/configurações dos passes mantidos fora do runtime reconstruído e sem mudanças neste trabalho.

## Arquitetura revisada

- `ReplicatedStorage/Shared/WorldBuilder.lua`: safe zone aberta, fazendas junto ao início da pista, oito biomas alinhados no mesmo eixo, ninhos e marcos temáticos. O passe adicional acrescenta bases, inlays, wedges, anéis, rochas facetadas e esculturas próprias por bioma.
- `ReplicatedStorage/Shared/AnimalFactory.lua`: fábrica procedural com anatomia por espécie e ramificações exclusivas para os oito guardiões: galinha, cisne, escorpião, tigre, yeti, cão infernal, baleia abissal e tiranossauro.
- `ReplicatedStorage/Shared/GuardianCatalog.lua` + `ServerScriptService/Services/GuardianController.lua` + `ServerScriptService/Services/GuardianAI.lua`: oito entidades com cérebros independentes; cada cérebro nasce pausado e só ativa após roubo confirmado no bioma correspondente. Ao terminar o transporte, o guardião volta ao repouso.
- `ReplicatedStorage/Shared/AnimalAnimator.lua` + `StarterPlayerScripts/AnimalAnimation.client.lua`: animação local e limitada por distância para animais selvagens (Walk), animais nas bases (Rest) e guardiões (Rest/Run), sem replicar milhares de mudanças de CFrame por segundo.
- `ReplicatedStorage/Shared/TreadmillAnimator.lua`: movimento local das faixas e roletes da esteira; melhorias atualizam cor, nível e ganho exibidos.
- `ServerScriptService/Services/ProfileStore.lua`: sanitização, bloqueio de sessão e persistência.
- `StarterPlayerScripts/InteractionPrompt.lua`: interface compacta de interação e tratamento do pressionar/soltar.
- `ServerScriptService/Main.server.lua`: coordena perfis, progressão, remotes, captura, guardiões, economia, estado das animações e ciclo de vida dos jogadores.

## Verificação local

Execute a partir da raiz do repositório:

```bash
python3 tools/validate_roube_animal.py
luau tools/tests/run.luau
python3 tools/tests/test_map_layout.py
python3 tools/tests/test_monetization.py
python3 tools/tests/test_core_reliability.py
python3 tools/tests/test_studio_audit.py
python3 tools/tests/test_guardian_ai.py
python3 tools/tests/test_release_safety.py
rojo build default.project.json --output build/StealAnAnimal.rbxl
python3 tools/tests/test_rbxl_file.py build/StealAnAnimal.rbxl
python3 tools/simulate_studio_run.py --report artifacts/studio-run-simulation.json --markdown artifacts/studio-run-simulation.md --place build/StealAnAnimal.rbxl
```

O GitHub Actions executa as verificações de sintaxe Luau, regras, estrutura, mapa, HUD, persistência, bots, monetização, build Rojo, arquivo RBXL e simulação de layout. O relatório fica no artefato `StealAnAnimal-simulated-studio-report`.

**Limite da validação:** a simulação de CI não executa o motor Roblox, física, DataStore real, replicação, ProximityPrompt real nem toque em um aparelho. Antes de publicar, abra o artefato RBXL no Roblox Studio, use o plugin de auditoria descrito em [docs/STUDIO_AUTOMATED_AUDIT.md](docs/STUDIO_AUTOMATED_AUDIT.md), teste com clientes simulados e faça uma sessão de teste no celular. Guarde o SHA do commit testado como `STEAL_ANIMAL_STUDIO_QA_SHA` nas variáveis do repositório. A publicação manual só prossegue se as duas confirmações forem marcadas e essa variável corresponder exatamente ao commit publicado.

## Pesquisa, auditoria e salvamentos

- [Auditoria e reescrita completa de 20/10/2026](docs/FULL_GAME_AUDIT_2026-10-20.md)
- [Pesquisa visual do mapa](docs/STEAL_AN_EGG_MAP_RESEARCH_2026-10-20.md)
- [Pesquisa de HUD mobile](docs/HUD_DESIGN_RESEARCH_2026-10-20.md)
- [Auditoria automatizada no Studio](docs/STUDIO_AUTOMATED_AUDIT.md)
- [Prancha de referências visuais do mapa e cercados](docs/visual/STEAL_AN_EGG_REFERENCE_BOARD.svg)
- [Conceito visual original dos oito guardiões](docs/visual/GUARDIAN_CONCEPTS.svg)
- [Conceito técnico e plano de animação da esteira](docs/visual/TREADMILL_CONCEPT.svg)
- [Reconstrução 3D de referências — v2](docs/3d/REFERENCE_RECONSTRUCTION_V2.md)
- [Manifesto de imagens e geometria — v2](docs/3d/reference_manifest_v2.json)
- [Manifesto dos backups](docs/SAVE_MANIFEST_2026-10-20.md)

Não há publicação automática após a validação. Publicar é uma operação separada e bloqueada até a aprovação explícita de um teste real do Studio para o mesmo commit.
