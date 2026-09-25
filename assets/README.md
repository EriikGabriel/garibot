# Biblioteca de assets

## Garibot original

Origem: [EriikGabriel/garibot, branch Rick](https://github.com/EriikGabriel/garibot/tree/Rick/game_files/assets).
Snapshot: `e27bc34d2292cb4a03261a3f699de33bd5069e75`.

Os recursos novos estão em `garibot1/`. Foram importados 378 arquivos (aproximadamente
10,9 MB); 23 entradas idênticas reutilizam arquivos já presentes ou outra entrada
do pacote. O `garibot1/manifest.json` relaciona cada caminho original ao caminho
local, tamanho e hash Git SHA-1 verificado durante o download.

| Pasta em `garibot1/` | Uso sugerido |
| --- | --- |
| `sprites/collectibles/` | Eletrônicos, placas, materiais e versões desmontadas para coleta e minigames de REEE. |
| `sprites/lixeira/` | Separação de materiais por lixeira. |
| `sprites/recycler/`, `sprites/main_recicler/`, `sprites/printer/`, `sprites/usina/` | Reciclagem, desmontagem, fabricação e processamento. |
| `sprites/tilesets/`, `sprites/map/`, `sprites/scenery/`, `sprites/stage_elements/` | Construção e decoração de fases. Os PNGs não incluem colisões ou TileSets prontos para Godot 4. |
| `sprites/people/`, `sprites/dog/`, `sprites/other_garibots/`, `sprites/enemies_rig/`, `sprites/enemies_frames/` | Personagens e inimigos; spritesheets e peças para animar. |
| `sprites/ui/`, `sprites/mobile_buttons/`, `sprites/bar/`, `sprites/game_ui/` | Menus, indicadores, teclas, HUD e botões do jogo original. |
| `audio/ui/` | Seleção, confirmação e respostas corretas/incorretas. |
| `audio/dialogs/`, `audio/sfx/`, `audio/enemy_sfx/`, `audio/stage_3/` | Vozes sintéticas, ações e máquinas. |
| `audio/songs/`, `audio/recycle_anim/` | Música da fase 1, menu, bônus, fanfarras e sequência de reciclagem. |

Foram deixados de fora caches de importação, arquivos temporários, scripts e recursos
de cenas antigas, fontes sem licença acompanhando os arquivos, projetos de desenho
`.kra` e faixas alternativas/narrativas específicas não selecionadas. A relação está
no campo `not_imported` do manifesto. Os sons estão disponíveis para uso e ainda não
foram vinculados automaticamente a eventos do jogo.

### Créditos e origem

Créditos consultados: [Credits.tscn do snapshot original](https://github.com/EriikGabriel/garibot/blob/e27bc34d2292cb4a03261a3f699de33bd5069e75/game_files/scenes/menu/Credits.tscn).

- Arte e animações: Anderson Pinheiro Garrote, Giovanni Marçon Rossi e Rodrigo Gonçalves.
- Música: André Matheus Bariani Trava.
- Projeto original: Garibot e o Mundo de Resíduos, UFSCar Sorocaba, 2021.

Os arquivos foram trazidos do repositório indicado pelo responsável pelo projeto.
Não foi localizado um arquivo de licença explícita no snapshot; estes assets mantêm
a autoria e os direitos originais e **não** recebem a licença CC0 da Kenney.

## GUI pixel art — Kenney

Pacote: [UI Pack – Pixel Adventure](https://kenney.nl/assets/ui-pack-pixel-adventure).
Arquivos em `gui/kenney_pixel_adventure/`, com [licença CC0](gui/kenney_pixel_adventure/license.txt)
original e manifesto de origem/SHA-256. A versão indicada pelo arquivo de licença é 2.0.

- `tiles/large_tiles/`: peças de 32 × 32 pixels.
- `tiles/small_tiles/`: peças de 16 × 16 pixels.
- `thick_outline/` e `thin_outline/`: duas espessuras de contorno.
- `tilesheets/`: atlas com espaçamento de 1 px e versões compactadas sem espaçamento.
- `preview.png` e `sample.png`: catálogo e exemplos do autor.

Os nomes numerados foram preservados para corresponder aos atlas. As texturas são
originais, sem redimensionamento. Use filtro **Nearest** no CanvasItem para conservar
os pixels; o projeto já usa esse filtro por padrão.

## Usar e editar no Godot

1. Abra `gui/asset_preview/asset_preview.tscn` para ver amostras e controles reais;
   use F6 para experimentar os estados dos botões, o slider e o campo de resposta.
2. O tema `gui/themes/pixel_adventure/pixel_adventure_theme.tres` utiliza as texturas
   da Kenney como StyleBoxTexture com bordas preservadas. Arraste-o para a propriedade
   **Theme** do Control raiz de uma nova tela. Cores, margens e estados são editáveis
   pelo Inspector. Os estilos locais de controles existentes têm prioridade sobre o tema.
3. Para imagens do Garibot, arraste PNGs para TextureRect ou Sprite2D. Os spritesheets
   precisam de regiões/frames apropriados; os sons podem ser arrastados para AudioStreamPlayer.
4. Ao procurar um arquivo reaproveitado, consulte `garibot1/manifest.json`: o campo
   `path` indica o recurso canônico, mesmo quando ele está fora de `garibot1/`.

O tema agora está aplicado globalmente pelo `project.godot`, com a fonte Pixelify
Sans (licença SIL OFL em `fonts/pixelify_sans/`). As telas compartilham os estilos;
consulte `gui/themes/pixel_adventure/README.md` para editar as variações no Godot.
Nenhuma lógica do jogo original foi importada.
