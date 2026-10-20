# Pesquisa visual do mapa — Steal An Egg
Data: 2026-10-20

## Objetivo e limite
A pesquisa informa a linguagem visual e a organização espacial do mapa do projeto. As imagens abaixo são referências externas para análise, não assets copiados para o jogo. O mapa implementado usa peças Roblox originais.

## Referências analisadas
1. Página oficial da experiência e descrição do loop: https://www.roblox.com/games/107778070777162/Steal-An-Egg
2. Captura do campo verde e do bioma Forest: https://games.gg/cdn-cgi/image/width%3D1920%2Cquality%3D75%2Cformat%3Dauto%2Cfit%3Dscale-down%2Cmetadata%3Dnone%2Conerror%3Dredirect/https%3A/assets.games.gg/image_69e8820769.png
3. Captura de cercados, áreas de jogadores e interface Shop/Index: https://www.phucanh.vn/media/news/1509_steal-an-egg-roblox-5.jpg
4. Captura ampla de cercados, zona segura, banca SELL e guardião gigante: https://resource.supercheats.com/library/supercheats/740w/2026/steal-an-egg-screenshot-01.webp
5. Captura de ovos no chão e guardião grande: https://cdn-media.sforum.vn/storage/app/media/phuonganh/phuonganh/cach-choi-steal-egg-roblox-2.jpg
6. Corredor de corrida longo com paredes laterais, luzes e portal: https://assets.games.gg/5bdcd10f_4443_43be_8ce5_e751994655ce_1_c052b4731b.png
7. Guia de mapa/biomas e requisitos (fonte comunitária, números sujeitos a mudanças): https://steal-an-egg.robloxgameswiki.com/guide/biomes-map
8. Guia para iniciantes e ciclo roubar → escapar → chocar → ganhar → melhorar: https://steal-an-egg.robloxgamewiki.com/guide/beginner-guide/

## Observações visuais
- O chão é predominantemente verde vivo com textura quadriculada; a leitura do percurso vem da cor do terreno, dos caminhos e das paredes, não de uma decoração densa.
- O percurso principal é comprido e fácil de reconhecer de qualquer ponto. Paredes laterais altas impedem que o jogador perca a orientação.
- As áreas de jogadores são retangulares, delimitadas por cercas baixas e visualmente separadas. A entrada é legível e as áreas internas continuam abertas para ver ovos/pets.
- Ovos são objetos grandes, coloridos e colocados em ninhos/pontos de interesse. Eles devem contrastar com o chão e aparecer antes de o jogador chegar perto.
- Guardiões exageradamente grandes funcionam como marcos visuais; não devem bloquear a leitura do caminho inteiro.
- Biomas mudam a paleta e os objetos de fundo, mas o caminho central continua desobstruído. A decoração fica nas laterais, não no corredor de corrida.
- Shop/Index e os indicadores de dinheiro/velocidade são grandes, coloridos e fáceis de reconhecer em tela pequena.
- A imagem de corrida mostra outro uso de corredor comprido: paredes, marcos luminosos e um destino claramente visível. A referência serve para orientação espacial, não para copiar a estética de lava/portal.

## Especificação aplicada nesta reconstrução
- Corredor de 1.500 studs, caminho central, bordas luminosas e paredes laterais.
- Oito zonas coloridas existentes mantidas para não quebrar a progressão, cada uma com paisagismo, letreiro, ninho visual e três ovos decorativos.
- Oito fazendas em grade 4×2, com cercas de madeira em dois níveis e abertura frontal; a decoração das cercas não bloqueia o jogador.
- Guardiões grandes e animais ficam fora do eixo principal para reduzir colisões visuais.
- A prévia serializada do Workspace contém as paredes, ninhos, ovos e cercas; o servidor constrói a cena jogável em uma árvore separada.
- A interface recebeu uma paleta mais saturada e contraste maior. A interface não copia a arte, os ícones ou os assets do jogo de referência.

## Limitações e validação
As capturas são screenshots de terceiros e podem mostrar versões antigas ou eventos temporários. Números exatos de biomas e requisitos de velocidade em wikis comunitárias entram em conflito, então não foram usados como verdades rígidas. O mapa desta versão mantém oito zonas autorais. A CI valida sintaxe, regras, estrutura do mapa, serialização RBXL e build Rojo; isso não substitui um playtest no Roblox Studio.
