# STEAL AN ANIMAL — Mapa de oito fases

## Planta

O mapa usa oito fazendas retangulares em duas fileiras de quatro, ao redor do ponto de entrada. À frente delas começa um corredor largo e contínuo. A faixa central é de pedra clara, as bordas são luminosas e os elementos de cenário ficam fora da área de corrida para não bloquear o caminho.

## Fases e guardiões adultos

1. Prado Solar — Galinha.
2. Lago das Asas — Cisne.
3. Floresta Sussurrante — Lobo.
4. Pântano Nebuloso — Crocodilo.
5. Pico Congelado — Urso Polar.
6. Savana Dourada — Leão.
7. Vulcão de Âmbar — Dragão.
8. Abismo Azul — Baleia.

Cada zona tem cores próprias, portal com número da fase, animais bebês capturáveis e um guardião adulto ampliado. O guardião da fase final é uma baleia. Os animais armazenados continuam passando por bebê, criança, adolescente e adulto, com aumento de 50% de renda em cada evolução.

## Linguagem dos modelos

Os modelos são montados com Parts nativas e formas esféricas alongadas, não com malhas retiradas de outro jogo. A galinha tem crista e barbela; o cisne tem pescoço alto, bico e penas de asa; o urso tem focinho, orelhas e patas; os animais marinhos usam corpo alongado, nadadeiras, cauda e barriga contrastante. Cada espécie recebe uma silhueta complementar à sua paleta.

## Referências visuais consultadas

- Página oficial de Steal An Egg no Roblox: https://www.roblox.com/games/107778070777162/Steal-An-Egg
- Captura de gameplay com guardião grande, ovos e piso verde: https://cdn-media.sforum.vn/storage/app/media/phuonganh/phuonganh/cach-choi-steal-egg-roblox-2.jpg
- Captura de gameplay com áreas cercadas e animais: https://www.phucanh.vn/media/news/1509_steal-an-egg-roblox-5.jpg
- Imagem de referência do guardião de galinha: https://kinglabbok.com/assets/guardian.jpg

As imagens servem apenas como referência de composição, hierarquia visual e escala. O novo mapa não reproduz o mapa original; suas fazendas, oito biomas, distribuição, cores, sinalização e modelos procedurais foram desenhados para este projeto.


## Esteiras e velocidade — revisão r5

Cada uma das oito fazendas tem uma esteira com faixa animada e um painel de melhoria. Permanecer sobre a faixa gera pontos de velocidade no servidor, sem confiar em valores enviados pelo cliente; não é preciso andar para fora da esteira para treinar. As melhorias são compradas com moedas do jogo; não existem gamepasses.

- Esteira inicial: +2 pontos de velocidade por segundo correndo na área da faixa.
- Cada nível de esteira aumenta o rendimento em 1,5×; máximo de 10 níveis.
- Velocidade de movimento calculada: 16 + raiz quadrada dos pontos × 0,35, limitada a 40 studs/s.
- Carregar um animal aplica a penalidade de peso depois do cálculo da velocidade.
- O HUD mostra pontos acumulados, nível da esteira, ganho por segundo e velocidade de movimento.

Referências consultadas antes e depois da implementação:
- Descrição oficial de Steal An Egg (inclui treinar velocidade na esteira e melhorá-la): https://www.roblox.com/games/107778070777162/Steal-An-Egg
- Captura visual pública da esteira e sua faixa iluminada: https://eggipedia.com/images/sae/shots/tapis.webp
- Guia comunitário para o conceito de progresso e esteira: https://steal-an-egg.robloxgamewiki.com/progression/treadmill-guide

As referências orientaram apenas a função da esteira, a faixa escura com detalhes luminosos, o mostrador de treino e a relação entre velocidade e fuga. O equipamento e o mapa foram montados em Parts nativas com posicionamento, formas, cores e geometria próprios.


## Revisão de carregamento do mapa — r6

O arquivo anterior era bem-formado como binário, mas continha somente scripts, módulos e serviços, sem peças serializadas em Workspace. A cena surgia apenas quando o Script de servidor executava em Play; abrir o arquivo no modo de edição podia mostrar Workspace vazio.

A correção adiciona uma planta física em Workspace/StealAnAnimalWorld.model.json: corredor, oito portais, fazendas retangulares, oito esteiras, guardiões adultos e animais de amostra. O servidor constrói uma versão interativa separada em StealAnAnimalRuntimeWorld e remove o preview somente após concluir a criação do cenário, das fazendas, dos animais selvagens e dos guardiões. Se a inicialização falhar antes disso, a planta estática não é destruída.

O CI analisa o arquivo binário recém-gerado: cabeçalho RBXL, descompressão LZ4 de cada bloco, limites, contagem de classes/instâncias, Workspace, centenas de Parts, bloco PRNT e terminador END. Essa validação estrutural é feita só por código; não substitui executar o jogo dentro do Roblox Studio.
