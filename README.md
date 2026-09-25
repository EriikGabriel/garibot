# Garibot e o Mundo de Resíduos

Jogo de plataforma 2D desenvolvido em Godot 4. O projeto usa cenas pequenas e
componentes reutilizáveis para separar personagem, interface, fases e regras
de jogo.

## Estrutura do projeto

| Caminho | Responsabilidade |
| --- | --- |
| `assets/` | Sprites, sons e demais recursos brutos. |
| `assets/garibot1/` | Sprites e sons importados do Garibot original, com manifesto de origem. |
| `assets/gui/kenney_pixel_adventure/` | Pacote CC0 de interface em pixel art. |
| `gui/asset_preview/` | Cena editável de amostras e controles com o tema pixel art. |
| `gui/themes/` | Temas reutilizáveis de interface. |
| `components/` | Componentes reutilizáveis, como vida, hitbox e dano de contato. |
| `scenes/characters/` | Cenas e scripts de personagens, incluindo Garibot. |
| `scenes/cutscene/` | Diretor de cutscenes reutilizável. |
| `gui/settings/` | Telas e controles modulares de configurações. |
| `levels/` | Fases jogáveis e scripts específicos de fase. |
| `gui/` | Interface principal do jogo. |
| `scripts/` | Autoloads e serviços globais, como configurações e troca de cenas. |
| `addons/dialogic/` | Plugin de diálogos de terceiros; evite editar sem necessidade. |

## Execução

Consulte [a biblioteca de assets](assets/README.md) para pastas, créditos e instruções
de uso dos recursos importados. O tema e a cena de amostras podem ser editados no Godot.

Abra `project.godot` no editor Godot 4 ou execute, na raiz do projeto:

```bash
godot4 --path .
```

Caso o executável tenha outro nome no sistema, substitua `godot4` pelo comando
equivalente.

## Convenções de manutenção

- Use `@export` para valores ajustáveis pelo editor, evitando números mágicos.
- Mantenha uma cena por componente reutilizável em `components/`.
- Preserve os caminhos dos recursos `.tscn`, `.gd` e `.tres`: eles são usados
  diretamente pelo Godot.
- Prefira nomes descritivos, tipagem em GDScript e comentários em PT-BR para
  decisões que não sejam óbvias.
- Ao criar uma preferência, registre-a em `scripts/settings.gd`, aplique seu
  efeito em `apply_setting` e vincule a chave a um controle em
  `gui/settings/`.
- Não altere `addons/dialogic/` para lógica específica do jogo; coloque essa
  integração em cenas ou scripts próprios.

## Verificação antes de enviar alterações

1. Abra o projeto no editor para reimportar recursos e verificar avisos.
2. Rode a fase ou cena afetada.
3. Confirme que não há marcadores de conflito (`<<<<<<<`, `=======`,
   `>>>>>>>`) nem arquivos gerados em mudanças versionadas.
