# Áudio do jogo

`game_audio.tscn` é o autoload `GameAudio`. Edite os streams e os volumes dos
players pelo Inspector. A música continua entre menus, fase e pausa; usa o bus
`Music`. Interface, coleta, respostas e vozes usam `Sfx` e respeitam as preferências.

| Evento | Asset de `assets/garibot1/audio/` |
| --- | --- |
| Tema em loop | `recycle_anim/garibot_theme_last_versionipromise.mp3` |
| Navegação por mouse/teclado | `ui/ui_move.mp3` |
| Confirmar | `ui/ui_select.mp3` |
| Voltar / pular | `ui/ui_deselect.mp3` |
| Iniciar jogo | `ui/ui_main_menu_select.mp3` |
| Coletar REEE | `recycle_anim/recycle_anim_insert.mp3` |
| Resposta correta / incorreta | `ui/correct_answer_1.mp3`, `ui/wrong_answer.mp3` |
| Cruzadinha concluída | `ui/correct_answer_3.mp3` |
| Associações concluídas | `songs/win-fanfare.mp3` |
| Garidog / criança falando | `dialogs/talk_garidog.mp3`, `dialogs/talk_kid.mp3` |

Botões são conectados automaticamente, inclusive os criados durante a pausa.
Use o metadata `audio_cue` para escolher um som específico, ou uma string vazia
quando o botão já tem feedback próprio. A navegação limita disparos consecutivos.
Para eventos de gameplay, chame `GameAudio.play_sound(&"collect")`, por exemplo.
Os minigames emitem `answer_checked` e continuam reutilizáveis sem depender do áudio.

As vozes tocam uma vez por fala e param ao terminar o texto ou o diálogo.
O loop da música é aplicado a uma cópia do stream, sem alterar os assets originais.
Pulo, giro e dano mantêm seus players existentes. Sons de armas, inimigos e máquinas
ficam disponíveis nos assets para quando suas respectivas mecânicas forem integradas.
