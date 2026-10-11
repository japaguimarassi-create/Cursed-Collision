# ROUBE UM ANIMAL — Guia do Projeto

## Visão geral

ROUBE UM ANIMAL é um simulador de exploração e risco para Roblox. O jogador treina na própria base, entra em biomas progressivamente mais perigosos, captura um animal, sofre uma penalidade de velocidade baseada no peso e tenta voltar ao próprio curral antes de ser alcançado por um guardião. A venda credita moedas de acordo com o valor-base, a raridade e os gamepasses ativos.

O mapa inicial é montado por código no servidor para que a experiência seja reproduzível por Rojo. Os animais procedurais são modelos estilizados de formas geométricas: servem como arte-base jogável e devem ser substituídos ou refinados com meshes, animações e efeitos próprios antes de uma versão comercial.

## Estrutura

- src/RoubeUmAnimal/ReplicatedStorage/Shared/Config.lua: limites, progressão, cooldowns e IDs configuráveis.
- src/RoubeUmAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua: catálogo de espécies, biomas, pesos, requisitos de força, raridade e valor-base.
- src/RoubeUmAnimal/ServerScriptService/Main.server.lua: bootstrap e ciclo de vida dos jogadores.
- Services/ProfileService.lua: leaderstats, carregamento, sessão, autosave e moedas.
- Services/WorldBuilder.lua: mapa, bases, estações, animais, guardiões procedurais e iluminação.
- Services/AnimalService.lua: captura, ferramenta, modelo carregado, venda e respawn.
- Services/TrainingService.lua: esteiras e supinos.
- Services/ShopService.lua: upgrades comprados com moedas.
- Services/PassService.lua: propriedade e prompts de gamepasses.
- Services/GuardianService.lua: visão, patrulha, perseguição e PathfindingService.
- StarterPlayer/StarterPlayerScripts/GameClient.client.lua: HUD móvel e notificações.

## Loop de gameplay

1. O jogador entra e recebe um dos oito currais.
2. Correr na esteira concede Velocidade; interagir no supino concede Força.
3. O jogador aproxima-se de um animal e mantém a interação de roubo.
4. O servidor verifica os dados do catálogo, distância, força necessária e se o jogador já carrega outro animal.
5. O animal passa a uma Tool lógica e um modelo visual é preso às costas.
6. O peso reduz a velocidade com a fórmula descrita abaixo.
7. Um guardião pode detectar o jogador que transporta um animal e persegui-lo.
8. Ao tocar o SellPart do próprio curral, o jogador recebe as moedas calculadas pelo servidor. Se for capturado, morrer ou sair durante o transporte, perde o animal e ele reaparece após um intervalo.

## Fórmulas da progressão

### Velocidade

Velocidade-base:

**BaseSpeed = min(160, 16 + SpeedLevel × 0.75 + VIPBonus)**

O gamepass VIP acrescenta 50 à velocidade-base calculada. O valor é aplicado ao Humanoid pelo servidor, mas WalkSpeed não é uma barreira antitrapaça; jogos competitivos devem acrescentar validações de deslocamento.

### Penalidade por peso

Seja **ratio = Weight / Strength**:

**penalty = clamp((ratio - 0.45) × 0.28, 0, 0.78)**

**EffectiveSpeed = max(5, BaseSpeed × (1 - penalty))**

RequiredStrength é um requisito de captura distinto da penalidade de peso. Assim, ser forte o bastante para roubar um animal não garante que seja possível carregá-lo rapidamente.

### Venda

**Sale = floor(BaseValue × RarityMultiplier)**

O pass de moedas em dobro multiplica essa venda por dois. Os valores e os multiplicadores encontram-se no catálogo e no Config.lua; o cliente nunca informa quanto deve receber.

## Mapa procedural

### Hub e currais

- Plataforma central de grama com sinalização ampla para o título da experiência.
- Oito currais individuais com cercas de madeira clara, placa de proprietário, zona de spawn e uma área de venda em neon verde.
- A esteira fica no lado esquerdo do curral, com trilhos azuis; o supino fica do lado direito, com barra metálica e pesos azuis.
- A peça SellPart tem luz verde. O servidor aceita a venda somente se o dono do curral corresponder ao UserId do jogador.
- A capacidade de oito jogadores por servidor deve ser configurada na página da experiência ou aumentada junto com a quantidade de currais.

### Zona 1 — Fazenda fofa

A região é verde-clara, com caminhos de terra, árvores arredondadas e sinalização dourada. Os animais iniciais são Galinha, Capivara e Cabra. A silhueta deve ser legível, com cores claras e espaços generosos entre pontos de interação.

### Zona 2 — Selva mística

O chão torna-se verde profundo, com copas de árvores densas e a sinalização em verde-ciano. Macacos, Araras, Onças e Pandas aparecem nesta região. Para enriquecer a versão artística, adicione volumes de névoa local, ruínas cobertas de musgo, partículas suaves, sons de fauna e pequenas luzes turquesa. Evite obscurecer os prompts ou os caminhos de fuga.

### Zona 3 — Vulcão

A pedra escura contrasta com luzes de lava laranja e vermelha. Tigres Vulcânicos, Raposas de Lava e Fênix são os animais de maior valor. A lava causa dano ao tocar; mantenha pontes e rotas de fuga claramente legíveis. Use iluminação quente perto da lava, mas não pinte todo o bioma com vermelho.

## Lighting usado pelo WorldBuilder

Os efeitos são aplicados por código para garantir uma configuração consistente:

| Propriedade | Valor |
|---|---:|
| Lighting.Technology | Future |
| ClockTime | 14 |
| Brightness | 2.1 |
| ExposureCompensation | 0.05 |
| GlobalShadows | true |
| EnvironmentDiffuseScale | 0.4 |
| EnvironmentSpecularScale | 0.65 |
| Atmosphere.Density | 0.22 |
| Atmosphere.Offset | 0.1 |
| Atmosphere.Haze | 1.15 |
| Atmosphere.Glare | 0.18 |
| ColorCorrection.Brightness | 0.02 |
| ColorCorrection.Contrast | 0.08 |
| ColorCorrection.Saturation | 0.14 |
| Bloom.Intensity | 0.22 |
| Bloom.Size | 28 |
| Bloom.Threshold | 1.05 |
| SunRays.Intensity | 0.075 |
| SunRays.Spread | 0.72 |

O código preserva um Sky existente. Para trocar o céu, escolha um skybox de uso autorizado no Creator Store e configure suas seis faces no Studio; o projeto não usa IDs aleatórios de skybox.

## Construção e execução

1. Instale Rojo pelo Rokit usando o arquivo rokit.toml.
2. Execute: `rojo build default.project.json --output build/RoubeUmAnimal.rbxl`.
3. Abra o arquivo gerado no Roblox Studio.
4. Publique primeiro em uma experiência de teste privada.
5. Habilite o acesso a API Services no Studio para testar DataStore em uma experiência apropriada. Não use o DataStore de produção para testes destrutivos.
6. Confirme que os perfis carregam, que a venda só funciona no curral do dono e que os dados permanecem após sair e entrar.
7. Crie os gamepasses no Creator Dashboard e informe os IDs reais em Config.lua. O valor 0 significa desativado.
8. Teste no dispositivo móvel e no computador antes de publicar.

## Segurança e limites conhecidos

- Todas as recompensas, custos, capturas e vendas são calculados no servidor.
- Eventos de proximidade são validados por distância e contexto; as propriedades visuais do prompt não são tratadas como segurança.
- Dados usam UpdateAsync e um token de sessão com expiração. Ainda é necessário testar comportamento em falhas de rede e reconexão antes de produção.
- A arte dos animais e os guardiões são geométricos. Este é um protótipo funcional de gameplay, não uma produção AAA final.
- A publicação no Roblox é manual e requer IDs próprios configurados no GitHub Actions. Não configure o novo projeto para sobrescrever a antiga experiência.
