# Auditoria completa e reescrita — 2026-10-20

## Escopo

Auditoria do repositório `japaguimarassi-create/Cursed-Collision`, experiência `Steal An Animal`, com foco em código de gameplay, HUD mobile, mapa, modelos, estado do jogador, persistência, Bots BotX, testes de regressão e publicação.

## Defeitos identificados e correções aplicadas nesta branch

### Ciclo de vida das fazendas
O antigo `PlayerRemoving` apagava `playerBases[player]` antes de chamar `releaseBase(player)`. Como a função de liberação usava essa referência para localizar a fazenda, a fazenda podia não voltar ao conjunto disponível. A referência é agora limpa dentro de `releaseBase`, e o teste de regressão verifica a ordem.

Também foi adicionado um guardião `playerSetupDone` ao fluxo `PlayerAdded` para que a conexão do evento e a inicialização de jogadores já presentes não executem a alocação duas vezes para o mesmo jogador.

### Persistência e encerramento
A sanitização do perfil, aquisição do bloqueio de sessão, snapshot, save e release passaram para `Services/ProfileStore.lua`. Se o save final falhar durante a saída ou o encerramento do servidor, o código não tenta remover o bloqueio como se o save tivesse sido confirmado; abandona a referência local e deixa a concessão expirar naturalmente. Isso reduz o risco de dois servidores gravarem o mesmo perfil depois de uma falha.

Isso não garante disponibilidade do DataStore nem elimina todos os cenários de perda de rede; esses cenários ainda exigem teste no ambiente Roblox.

### Mapa e modelos
A construção das fazendas, cercas, esteiras, letreiros e cenário passou para `Shared/WorldBuilder.lua`. Os modelos dos animais e estágios passaram para `Shared/AnimalFactory.lua`. Uma segunda faixa de geometria da borda do corredor foi removida. O modelo do cisne mantém o pescoço/cabeça dedicados e evita partes genéricas duplicadas.

### HUD e interações
A interface ProximityPrompt customizada foi isolada em `StarterPlayerScripts/InteractionPrompt.lua`. A caixa tem tamanho máximo de 280×48 e fica na área central entre os botões de menu e os controles inferiores. O botão de interação encerra a ação mesmo se o dedo/mouse for solto fora da caixa. A simulação de CI agora mede sua posição em vários perfis de viewport; ela não a renderiza no motor Roblox.

### Publicação
O workflow `.github/workflows/publish-roblox.yml`, que publicava automaticamente após uma validação bem-sucedida na `main`, foi removido. A revisão dos logs da execução anterior confirmou que essa automação publicou a versão Roblox 109. O novo workflow manual exige dois sinais de confirmação e a variável `STEAL_ANIMAL_STUDIO_QA_SHA` com o SHA exato do código aprovado em um teste real de Roblox Studio/celular.

A variável é uma atestação explícita de quem opera a publicação; a CI não consegue provar que a sessão real foi executada. O workflow não deve ser iniciado com essa variável preenchida até que o teste desse commit tenha sido realizado.

## Novos testes de regressão

- `tools/tests/test_release_safety.py`: ordem de liberação da fazenda, bloqueio de sessão após falha, modularização, prompt mobile e proteções de publicação.
- `tools/tests/test_core_reliability.py`: contrato de persistência e gameplay atualizado para os novos módulos.
- `tools/tests/test_map_layout.py`: contrato de mapa, silhuetas de animais, letreiros e interação.
- `tools/simulate_studio_run.py`: inclui módulos novos no hash/fonte auditada e modela a caixa de interação nas seis dimensões de teste existentes.
- `.github/workflows/validate.yml`: adiciona o teste de segurança de publicação à CI.

## Verificações necessárias

1. Todos os passos GitHub Actions devem terminar com sucesso, inclusive compilação Rojo, validação binária do RBXL e relatório simulado.
2. Abrir o artifact RBXL dessa execução no Roblox Studio.
3. Executar o plugin `Steal An Animal QA → Run Studio Audit` com perfil de telefone; guardar o relatório `[STEAL_ANIMAL_AUDIT_REPORT]`.
4. Testar no aparelho: abrir Shop/Index/More; capturar, carregar e depositar um animal; manter/soltar a interação; comprar melhoria de esteira; coletar; renascer em condições válidas; sair e entrar novamente para verificar o perfil e a reutilização da fazenda.
5. Só depois, registrar o SHA exato do commit aprovado em `STEAL_ANIMAL_STUDIO_QA_SHA` e usar o workflow manual com ambas as confirmações.

## Estado e limitações

Esta é uma revisão de código e uma preparação para validação; nenhum teste está marcado como aprovado antes que a respectiva execução seja verificada. Um parse limpo, testes unitários, build Rojo e simulação de geometria não comprovam ausência absoluta de bugs em um jogo de rede. Não existe base para afirmar “100% sem erros” sem teste real no Roblox Studio e no dispositivo-alvo.

A branch desta revisão é `rewrite/full-game-audit-20261020`. A experiência publicada anteriormente corresponde à versão 109; as alterações desta revisão não devem ser consideradas publicadas só por estarem no GitHub.
