# Tema global do Garibot 2

`pixel_adventure_theme.tres` é o tema padrão em `project.godot` → GUI → Theme.
Controles novos e criados por scripts herdam a fonte Pixelify Sans e os estilos.
Os menus, a HUD e os minigames usam os mesmos painéis; o Dialogic recebe a fonte
e a paleta por `dialogic/styles/`, sem alterações nos arquivos do plugin.

Edite no Inspector do recurso Theme:

- `Button`: estados normal, hover, pressionado, desabilitado e foco de teclado.
- `PrimaryButton`: ação principal dourada.
- `TitleLabel` e `MutedLabel`: títulos e texto de apoio.
- `CrosswordCell`: campo compacto para uma letra; mantenha as margens pequenas.
- `PanelContainer`, `HSlider`, `CheckBox` e `LineEdit`: componentes básicos.

Selecione **Theme Type Variation** no Control para usar uma variação. Overrides
locais ainda têm prioridade. As texturas de painel/botão são da Kenney (CC0);
os ícones SVG em `icons/` foram feitos para este projeto.

O layout acompanha o tamanho natural da janela, sem resolução virtual ou zoom
global. As configurações têm rolagem na área das páginas, mantendo os botões de
navegação visíveis.
O brilho global continua aplicado por cima de todas as interfaces.

Amostras: `gui/asset_preview/asset_preview.tscn`. Execute com F6 ou edite a cena
no editor. A fonte e sua licença estão em `assets/fonts/pixelify_sans/`.
