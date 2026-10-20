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
