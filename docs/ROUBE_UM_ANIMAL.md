# STEAL AN ANIMAL — guia técnico da reconstrução

## Escopo

A branch `main` contém uma reconstrução nova e mobile-first de **Steal An Animal**, com o mapa inspirado na leitura visual de **Steal An Egg**. Os ovos adicionados aos ninhos são, nesta versão, decoração do mapa; eles não substituem o ciclo de captura de animais implementado pelo servidor.

## Ciclo de jogo

1. Percorrer o corredor central e encontrar animais no bioma desbloqueado.
2. Capturar um animal usando o prompt de interação do próprio jogo.
3. Levar o animal até a fazenda do jogador e depositá-lo em um espaço disponível.
4. Receber renda passiva, permitir que o animal evolua e reinvestir moedas em melhorias da esteira.
5. Evitar o guardião durante a fuga; o servidor valida captura, depósito, coleta de renda, melhorias e renascimento.

O catálogo atual tem 29 espécies e o mapa tem oito biomas sequenciais. Cada fazenda tem seis espaços de animais e uma esteira melhorável. O renascimento exige 100.000 moedas e a velocidade máxima configurada; o limite é 25 renascimentos.

## Estrutura do mapa

- Um corredor comprido, com chão central, bordas e paredes laterais para definir o espaço jogável.
- Oito biomas: Prado Solar, Lago das Asas, Floresta Sussurrante, Pântano Nebuloso, Pico Congelado, Savana Dourada, Vulcão de Âmbar e Abismo Azul.
- Ninhos decorativos com três ovos em cada bioma, usados como referência visual para o estilo de Steal An Egg.
- Oito fazendas organizadas em uma grade 4×2, com cercas de dois níveis e entradas.
- Guardiões grandes e marcos ambientais específicos para diferenciar a progressão de cada bioma.

O arquivo `src/StealAnAnimal/Workspace/StealAnAnimalWorld.model.json` oferece uma prévia estática da geometria. Ao iniciar, o servidor constrói o mapa de runtime e remove a prévia somente após criar o mundo jogável.

## Sistemas e persistência

O servidor utiliza perfis persistentes com bloqueio de sessão, salvamento periódico e renda offline limitada. O código também implementa evolução em quatro fases, missões, recompensas diárias, códigos de resgate, estatísticas e MapBot. A interface foi projetada para telas móveis, com painéis e ações de toque.

## Passes e monetização legada

Os manifests e arquivos legados de passes/produtos foram preservados sem editar seus blobs originais na reconstrução. Entretanto, eles estão em `src/RoubeUmAnimal`, fora das rotas mapeadas pelo `default.project.json`, e não fazem parte do runtime novo. O arquivo legado `MonetizationIds.lua` contém IDs zerados. Portanto, **preservar os arquivos não significa que os passes estejam ativos ou que compras funcionem nesta versão**. Não publique compras até os IDs corretos e a integração serem verificados.

## Validação local

Na raiz do repositório, com Python 3, Luau e Rojo instalados:

```bash
python3 tools/validate_roube_animal.py
luau tools/tests/run.luau
python3 tools/tests/test_map_layout.py
python3 tools/tests/test_monetization.py
python3 tools/tests/test_core_reliability.py
rojo build default.project.json --output build/StealAnAnimal.rbxl
python3 tools/tests/test_rbxl_file.py build/StealAnAnimal.rbxl
```

A validação automatizada e a compilação não substituem um teste de partida no Roblox Studio em dispositivo móvel. A publicação de produção permanece manual e exige confirmação explícita e credenciais/IDs configurados no repositório.

## Referências internas

- [Pesquisa visual do mapa e fontes de referência](STEAL_AN_EGG_MAP_RESEARCH_2026-10-20.md)
- [Manifesto dos backups e estados salvos](SAVE_MANIFEST_2026-10-20.md)
