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

## Leitura em voz alta

Em **Configurações → Áudio e diálogo**, habilite **Leitura em voz alta**.
**Ctrl + Shift + R** também alterna a leitura em qualquer tela, inclusive na pausa.
Use Tab / Shift + Tab para navegar e Enter / Espaço para selecionar. Controles
focados são narrados com seus nomes e valores. A opção **Ler falas dos personagens**
inclui o nome do personagem e o texto dos diálogos do Dialogic.

A voz, velocidade e volume são configuráveis e persistidos em `user://settings.cfg`.
**Testar voz** funciona mesmo com a leitura desativada e atualiza a lista de vozes.
A seleção automática usa somente português brasileiro (pt-BR). Se essa voz não
estiver instalada, a tela avisa; outro idioma pode ser escolhido explicitamente.
O seletor tem busca por idioma, código ou nome da voz e uma lista com rolagem
de altura limitada. O volume da leitura também respeita o volume geral do jogo.
As vozes ficam em cache durante a sessão, inclusive quando não há vozes disponíveis.
A lista é criada ao abrir o seletor e reutilizada na busca; trocar de página não
consulta novamente o serviço de voz. Use **Testar voz** para atualizar esse cache.

No Linux, a síntese roda em um processo separado com **eSpeak NG** (ou eSpeak)
instalado no PATH. O áudio WAV é reproduzido pelo Godot, respeitando a pausa da
atividade e os volumes configurados. O TTS nativo fica desabilitado nesse sistema
para evitar bloqueios do Speech Dispatcher. Vozes da seleção correspondem às
disponíveis no eSpeak. Arquivos temporários são removidos após a leitura.
Se o processo não responder em 5 segundos, ele é encerrado e a narração suspensa;
o jogo permanece interativo. O aviso aparece acima dos minigames e o motivo fica
nas configurações. **Testar voz** permite tentar novamente.

Nos demais sistemas, permanece o TTS nativo: chamadas de 1,5 segundo ou mais
suspendem novas chamadas, e a ausência de início da voz em 5 segundos também.
Uma sessão nativa interrompida deixa uma marca de recuperação para a próxima
abertura. Nesse caminho, uma chamada nativa bloqueada só pode ser detectada
após retornar; a proteção não consegue interromper a chamada em andamento.

**Texto dos balões de fala** ajusta separadamente as falas, nomes e escolhas dos
balões (18 a 40 px), com preferência salva e aplicação ao balão aberto. Os balões
usam fundo branco e texto escuro. O controle geral de fonte continua independente.

Se não houver sintetizador ou voz disponível, a página mostra instruções,
sem impedir o uso do jogo. Reinicie o editor após mudar as configurações de TTS.

A integração fica em `scripts/speech.gd` e `scripts/speech_linux.gd`, sem alterações no plugin Dialogic.
Falas com dublagem reproduzida pelo subsistema Voice têm prioridade sobre a
síntese. Para controles sem texto, defina o metadado `speech_label`.
Mudanças rápidas de foco são agrupadas em 120 ms, sem filas crescentes de falas.
Na cruzadinha, a leitura inclui pista, direção, quantidade de letras, posição
da célula e resultado da verificação. Na associação, inclui seleção, função,
erros e acertos. Controles narrados pela própria atividade usam `speech_managed`
para evitar duplicidade com o foco global. Isso não inclui orientação espacial
para obstáculos nem integração com NVDA/Orca.

Verificação manual: ativar pelo atalho; navegar nos menus com Tab; alterar valores;
testar voz; ouvir e avançar uma fala; abrir e fechar a pausa; desativar durante a
leitura; reabrir o jogo para conferir persistência. Testar também sem vozes
instaladas e com uma fala dublada no Dialogic.

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
