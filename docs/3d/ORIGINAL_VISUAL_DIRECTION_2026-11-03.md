# Steal An Animal — direção visual original (03/11/2026)

## Princípio de identidade

Steal An Animal é uma experiência própria. Nenhuma construção, mascote, layout de interface, textura, marca ou composição específica de outro jogo deve ser reproduzida. As referências externas servem apenas para estudar legibilidade, escala, ritmo de progressão, densidade de cenário e leitura das áreas de gameplay.

## O que manter do nosso jogo

- Oito biomas próprios, em uma rota ampla e contínua.
- Animais originais como protagonistas e guardiões únicos.
- Bases individuais em formato de cercado aberto, sem casas ou celeiros.
- Percurso de roubo e fuga com velocidade, ninhos e retorno à base.
- Paleta, sinalização e formas geométricas próprias do projeto.

## Direção 3D implementada

O cenário usa volumes primários grandes, silhuetas de alto contraste e módulos geométricos secundários. A geometria é construída com combinações de blocos, cilindros, esferas controladas, WedgeParts, anéis poligonais, espigões facetados, raízes estruturais, costelas e placas sobrepostas. Textura não deve ser usada para fingir profundidade que precisa existir na malha.

- Hub: núcleo orgânico-cristalino, anéis poligonais e lâminas radiais.
- Floresta inicial: árvore monumental com raízes expostas, galhos estruturais, pétalas e folhas facetadas.
- Lago: formação rochosa em camadas, cascatas separadas e borda geométrica da piscina.
- Deserto: monólitos de arenito, placas inclinadas e arco de pedra.
- Selva: raízes entrelaçadas abertas, lâminas de copa e cápsulas luminosas; sem telhado ou pavilhão.
- Neve: conjunto de prismas de gelo assimétricos com núcleo central.
- Vulcão: crista de basalto, espigões, lava e anel térmico.
- Oceano Abissal: recife-coroa, espinha central, corais em leque e halo luminoso; sem torre ou edifício.
- Pré-histórico: costelas fósseis, fragmentos de ossos e crânio monumental.
- Bases: cercados abertos com bordas metálicas geométricas nos espaços dos animais; sem cobertura.

## Referências visuais consultadas

As imagens abaixo foram consultadas como estudos de composição e leitura do gênero, não como objetos para replicação:

1. Steal An Egg — gameplay com ovos e criatura de grande escala: https://cdn-media.sforum.vn/storage/app/media/phuonganh/phuonganh/cach-choi-steal-egg-roblox-2.jpg
2. Steal An Egg — cercados e áreas de base: https://resource.supercheats.com/library/supercheats/740w/2026/steal-an-egg-screenshot-01.webp
3. Steal An Egg — descrição geral e loop de gameplay: https://www.rolimons.com/game/107778070777162
4. Steal An Egg — biomas, guardiões e progressão em rota: https://rblxguide.com/games/steal-an-egg/biomes
5. Steal a Brainrot — distribuição de bases e corredor: https://staticg.sportskeeda.com/editor/2025/09/13a10-17582665019760-1920.jpg
6. Pet Simulator 99 — composição de zona com plataformas, árvores e grande escala: https://bigblog-storage.s3.us-east-1.amazonaws.com/ps99_fabled_highlands_time_trials_16b6fce6a7.png
7. Zoo Park Tycoon — habitat aberto com rochas, folhagem e cercas: https://tr.rbxcdn.com/180DAY-7035c1a783f1532ebd5e6c67a52777d5/768/432/Image/Webp/noFilter
8. Animal Tycoon — cenário low-poly com relevo angular e água: https://tr.rbxcdn.com/180DAY-9d0dbe321af6623574b1ed81cd6fd993/768/432/Image/Webp/noFilter
9. Roblox Pet Hunt — vegetação facetada, cercas, postes e sinalização: https://pbs.twimg.com/media/G-zCbETW8AAebxh.jpg

## Critérios de rejeição

- Nenhuma casa, celeiro, cabana ou telhado como peça dominante.
- Nenhum monumento composto apenas por um bloco retangular e uma placa.
- Nenhum corredor visualmente bloqueado ou com obstáculos no eixo de corrida.
- Nenhuma cópia reconhecível de asset, nome, personagem, paleta ou layout de referência.
- Não trocar geometria por textura quando volume e silhueta precisam ser legíveis.
- Não aumentar a densidade de peças ao ponto de comprometer o desempenho em celulares.

## Escopo desta revisão

Esta revisão altera o gerador procedural do mundo Roblox e mantém os sistemas de jogo. O projeto Blendstra separado permanece como arquivo de autoria e exige nova sessão de modelagem para substituir suas versões anteriores; não é tratado como se já estivesse sincronizado com o runtime Roblox.
