# Pesquisa visual do mapa — Steal An Egg
Data: 2026-10-20

## Objetivo e limite
A pesquisa informa a linguagem visual e a organização espacial do mapa do projeto. As imagens abaixo são referências externas para análise, não assets copiados para o jogo. O mapa implementado usa peças Roblox originais.

## Referências analisadas
1. Página oficial de Steal An Egg e descrição do ciclo de jogo: https://www.roblox.com/games/107778070777162/Steal-An-Egg
2. Steal An Egg: HUD Shop/Index e encontro com guardião de bioma: https://games.gg/cdn-cgi/image/width%3D1920%2Cquality%3D75%2Cformat%3Dauto%2Cfit%3Dscale-down%2Cmetadata%3Dnone%2Conerror%3Dredirect/https%3A/assets.games.gg/steal_an_egg_sakura_incubator_guide_deltias_gaming_fded6ba159.webp
3. Steal An Egg: cercados abertos, pets grandes e indicadores de dinheiro/velocidade: https://www.phucanh.vn/media/news/1509_steal-an-egg-roblox-5.jpg
4. Steal An Egg: captura ampla de cercados, zona segura e guardião: https://resource.supercheats.com/library/supercheats/740w/2026/steal-an-egg-screenshot-01.webp
5. Steal An Egg: ovos e guardião em bioma: https://cdn-media.sforum.vn/storage/app/media/phuonganh/phuonganh/cach-choi-steal-egg-roblox-2.jpg
6. Steal An Egg: corredor comprido, paredes laterais e marcos de progressão: https://assets.games.gg/5bdcd10f_4443_43be_8ce5_e751994655ce_1_c052b4731b.png
7. Steal An Egg: guia comunitário de biomas e guardiões (valores podem conflitar ou mudar): https://steal-an-egg.robloxgameswiki.com/guide/biomes-map
8. Steal a Brainrot: vista do terreno verde, tapete central vermelho e bases laterais: https://staticg.sportskeeda.com/editor/2025/09/13a10-17582665019760-1920.jpg
9. Steal a Brainrot: descrição comunitária do mapa e do papel de tapete e bases: https://stealabrainrotwiki.wiki/wiki/map-routes/
10. Steal An Egg: guia comunitário para iniciantes e ciclo roubar → escapar → chocar → ganhar → melhorar: https://steal-an-egg.robloxgamewiki.com/guide/beginner-guide/

## Observações visuais
- O chão é predominantemente verde vivo com textura quadriculada; a leitura do percurso vem da cor do terreno, dos caminhos e das paredes, não de uma decoração densa.
- O percurso principal é comprido e fácil de reconhecer de qualquer ponto. Paredes laterais altas impedem que o jogador perca a orientação.
- As áreas de jogadores são retangulares, delimitadas por cercas baixas e visualmente separadas. A entrada é legível e as áreas internas continuam abertas para ver ovos/pets.
- Ovos são objetos grandes, coloridos e colocados em ninhos/pontos de interesse. Eles devem contrastar com o chão e aparecer antes de o jogador chegar perto.
- Guardiões exageradamente grandes funcionam como marcos visuais; não devem bloquear a leitura do caminho inteiro.
- Biomas mudam a paleta e os objetos de fundo, mas o caminho central continua desobstruído. A decoração fica nas laterais, não no corredor de corrida.
- Shop/Index e os indicadores de dinheiro/velocidade são grandes, coloridos e fáceis de reconhecer em tela pequena.
- A imagem de corrida mostra outro uso de corredor comprido: paredes, marcos luminosos e um destino claramente visível. A referência serve para orientação espacial, não para copiar a estética de lava/portal.

## Especificação da reconstrução
- A leitura do mapa combina o corredor linear de roubo de ovos com o tapete vermelho, área gramada e fazendas laterais vistos em Steal a Brainrot. O corredor existente de 1.500 studs e a ordem das oito fases foram mantidos para não quebrar a progressão.
- A entrada tem uma faixa vermelha com detalhes dourados e, à frente, o corredor verde/cobblestone continua até os oito biomas; faixas de caminho, paredes com pilastras e pedras luminosas tornam a rota legível à distância.
- As fazendas continuam em grade 4×2. A fachada agora tem telhado em duas águas, cumeeira, porta, janelas coloridas, letreiro, balizas e um arco aberto de entrada; removemos a cerca branca extra que fechava visualmente a frente.
- Cada bioma recebeu um portal/coroa mais destacado, pedestal de ovos e detalhes orbitais de baixo custo, mantendo os objetos maiores afastados da trilha.
- Os guardiões agora alternam entre os lados do percurso, têm contorno luminoso, aura e coroa. Os filhotes ganharam olhos com íris/reflexos, sobrancelhas, bochechas e marcas no peito, além dos detalhes que distinguem espécies.
- O código monta o mapa jogável em uma árvore separada e remove a prévia ao fim da construção. A validação estática confirma estrutura e build; não prova sozinha a renderização ao vivo no Roblox.
- A implementação usa formas, paletas e geometria originais no lugar de imagens/meshes extraídos dos jogos de referência.

## Limitações e validação
As capturas são screenshots de terceiros e podem mostrar versões antigas ou eventos temporários. Números exatos de biomas e requisitos de velocidade em wikis comunitárias entram em conflito, então não foram usados como verdades rígidas. O mapa desta versão mantém oito zonas autorais. A CI valida sintaxe, regras, estrutura do mapa, serialização RBXL e build Rojo; isso não substitui um playtest no Roblox Studio.


## Reconstrução do mapa — 2026-11-03

A nova passagem visual mantém as oito fases autorais de Steal An Animal e adota a leitura de mapa observada em Steal An Egg: uma área segura de fazendas claramente recortadas, uma saída fácil de reconhecer e uma rota longa com progressão por regiões.

- A praça inicial agora recebe um piso quadriculado verde em peças leves, abaixo das fazendas e das superfícies de circulação. O padrão reforça o aspecto de campo aberto sem cobrir cercados, tapete de spawn ou estrada.
- Um portal de entrada marca a transição entre a praça segura e a Trilha Selvagem. As linhas de transição, marcadores laterais e placas de bioma tornam as mudanças de fase legíveis durante a corrida.
- Cada fase ganhou um marco visual diferente: flor monumental no Prado Solar, queda d'água no Lago das Asas, árvore gigante na Floresta Sussurrante, abrigo elevado no Pântano Nebuloso, conjunto de cristais no Pico Congelado, árvore de copa larga na Savana Dourada, vulcão luminoso no Vulcão de Âmbar e farol no Abismo Azul.
- Os marcos são posicionados fora da faixa central para preservar perseguições, fuga, coleta e navegação. A maior parte da decoração não é colidível; chão, estrada e estruturas de jogo continuam com suas colisões próprias.
- A identidade dos biomas permanece autoral. A referência é a organização espacial e a legibilidade de Steal An Egg, não a cópia de assets, nomes ou geometrias proprietárias.

A verificação automatizada cobre a presença dos marcos no construtor de mundo e a estrutura estática do Workspace. Ela não substitui a abertura do place e um teste de corrida no Roblox Studio em dispositivo móvel.


## Atualização de projeto — 2026-11-03

A ordem de fases mantida no código é: Floresta, Lago, Deserto, Selva, Neve, Vulcão, Oceano Abissal e Pré-histórico. A sequência de SPEED permanece 10 → 100 → 1.230 → 12.300 → 123.000 → 1.230.000 → 12.300.000 → 123.000.000. O requisito é validado na captura dos ovos; o jogador ainda pode percorrer fisicamente a pista.

A referência de guardiões inspira escala exagerada e estado de repouso junto aos ninhos. O projeto usa oito identidades originais com silhuetas próprias: Galinha Guardiã, Cisne Real, Escorpião das Dunas, Tigre Guardião, Yeti Glacial, Cão Infernal, Baleia Abissal e Tiranossauro Ancestral. Os modelos são construídos com peças/meshes originais pelo AnimalFactory, e o GuardianController controla o despertar, a perseguição, a captura e o retorno ao ponto de repouso.

A prancha vetorial [GUARDIAN_CONCEPTS.svg](visual/GUARDIAN_CONCEPTS.svg) é um conceito visual original para orientar os modelos; não é screenshot do jogo de referência. A prancha [STEAL_AN_EGG_REFERENCE_BOARD.svg](visual/STEAL_AN_EGG_REFERENCE_BOARD.svg) resume a linguagem visual observada e cita imagens públicas usadas no estudo. A imagem [TREADMILL_CONCEPT.svg](visual/TREADMILL_CONCEPT.svg) documenta peças da esteira e o movimento esperado.

As animações são separadas por responsabilidade: o servidor define o estado e move os guardiões; cada cliente anima localmente os membros e detalhes dos animais próximos. Faixa e roletes da esteira também são animados localmente. Esse arranjo reduz tráfego de replicação e preserva a autoridade do servidor sobre perseguição, alcance e captura.

A auditoria Studio foi ampliada para verificar oito tipos de guardião em repouso, animais selvagens com estado Walk, metadados da esteira e movimento local observado em dois clientes simulados. A simulação de CI apenas verifica fonte/estrutura; os movimentos reais precisam ser confirmados no StudioTestService.
