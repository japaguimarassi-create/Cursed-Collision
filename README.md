# ROUBE UM ANIMAL

Simulador de exploração, captura de animais, fuga dos guardiões e progressão por treino no Roblox.

Este repositório mantém o nome histórico Cursed-Collision, mas o projeto ativo de gameplay agora é **ROUBE UM ANIMAL**. Os códigos da experiência Collision Battlestar foram removidos da versão atual; arquivos de ferramentas de engenharia e documentação histórica que não faziam parte do runtime foram preservados.

## Ciclo do jogador

Entrar no servidor → receber um curral → treinar Velocidade na esteira e Força no supino → explorar a Fazenda, a Selva Mística e o Vulcão → roubar um animal → correr de volta ao próprio curral → vender o animal por Moedas.

Se um guardião alcançar o jogador durante o transporte, o animal é perdido e reaparece depois de um intervalo. Captura, requisitos de força, penalidade por peso, venda, preços, upgrades e gamepasses são validados no servidor.

## Sistemas incluídos

- Leaderstats em português: Moedas, Velocidade e Força.
- DataStore com UpdateAsync, token de sessão, autosave de cinco minutos e salvamento ao sair.
- Catálogo de animais com peso, raridade, requisitos de força e valor-base.
- Tool lógica com representação visual presa às costas durante o transporte.
- Penalidade progressiva de velocidade conforme o peso carregado.
- Venda restrita ao curral proprietário.
- Treino na esteira e no supino.
- Loja de upgrades de Força e Velocidade, com verificação de saldo no servidor.
- Gamepasses configuráveis: Moedas em Dobro e VIP com +50 de velocidade-base.
- Guardiões com detecção visual, patrulha e perseguição por PathfindingService.
- Mapa procedural estilizado e HUD adaptada para celular.
- Workflow para validar e gerar o arquivo Roblox place.

## Estrutura do projeto

A implementação Luau está em src/RoubeUmAnimal/. A configuração Rojo está em default.project.json. O guia do mapa, das regras e do procedimento de teste fica em docs/ROUBE_UM_ANIMAL.md.

## Build e validação

Com Rokit instalado:

    python3 tools/validate_roube_animal.py
    rojo build default.project.json --output build/RoubeUmAnimal.rbxl

O GitHub Actions executa a validação estrutural e constrói um arquivo de experiência para inspeção.

## Configuração necessária antes da produção

1. Publique uma experiência de teste separada e habilite DataStore para validar o salvamento.
2. Crie os gamepasses e substitua os IDs 0 em Config.lua pelos IDs reais.
3. Teste o comportamento dos guardiões, vendas, respawns, salvamento concorrente e HUD em dispositivos reais.
4. Defina ROUBE_ANIMAL_UNIVERSE_ID e ROUBE_ANIMAL_PLACE_ID como Repository Variables e ROBLOX_API_KEY como Repository Secret somente quando decidir publicar explicitamente.
5. Use manualmente o workflow de publicação e confirme o alvo antes de enviar uma versão.

A publicação automática da antiga experiência Collision Battlestar foi desativada para impedir que o novo jogo seja enviado para um ID antigo por engano.

## Ferramentas de engenharia preservadas

O repositório também conserva utilitários LuaSmith, scripts de teste e documentação de engenharia anteriores. Eles não fazem parte do runtime de ROUBE UM ANIMAL; o workflow ativo valida este projeto pelo script tools/validate_roube_animal.py.
