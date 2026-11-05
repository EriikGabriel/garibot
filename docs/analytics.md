# Telemetria (Analytics)

Autoload `Analytics` (`scripts/analytics/analytics.gd`). Registra decisões e dados de jogo
para análise posterior e exporta uma planilha.

## Ligar e desligar

```gdscript
const ENABLED := true   # false = nada é gravado nem enviado
const REMOTE_URL := ""  # vazio = só local (ver "Envio remoto")
```

## Onde ficam os dados

| O quê | Onde |
|---|---|
| Eventos de cada sessão | `user://analytics/sessions/<data>_<sessão>.jsonl` (uma linha JSON por evento) |
| ID anônimo do jogador | `user://analytics/player.cfg` |
| Planilhas exportadas | `user://analytics/exports/<data_hora>/` (`garibot_analise.xlsx` + um `.csv` por aba) |
| Cópia automática ao concluir a fase | `user://analytics/exports/ultima_fase_concluida/` |

`user://` no Linux: `~/.local/share/godot/app_userdata/Garibot 2/`.
No Windows: `%APPDATA%\Godot\app_userdata\Garibot 2\`.
Na Web, os dados ficam no navegador (IndexedDB) e a exportação baixa o `.xlsx`.

**Como exportar:**
- **F9:** só em builds de desenvolvimento.
- **Menu de pausa → "Exportar dados de análise":** abre a pasta.
- **Código:** `Analytics.export_data()`.

## Abas da planilha

| Aba | Conteúdo |
|---|---|
| Resumo | Uma linha por jogador: tempo, % de acerto (e na 1ª tentativa), "ouvir de novo", mortes, danos, REEE, minigames, preferências alteradas e de acessibilidade |
| Sessoes | Uma linha por sessão: início/fim, duração, versão, plataforma, idioma, resolução, fase concluída |
| Preferencias | Valores no início da sessão e cada mudança (antes → depois) |
| Dialogos | Início/fim de cada diálogo (duração, nº de falas) e cada fala exibida |
| Perguntas | Cada resposta: pergunta, alternativas, escolhida, certa/errada/ouvir_de_novo, tentativa, tempo de resposta |
| Minigames | Início/fim, respostas certas/erradas, pulos, perfeito, duração |
| Gameplay | Zonas, REEE, dano (fonte), mortes, renascimentos, quedas no rio, inimigos derrotados, pausas, fase concluída |
| Eventos | Log bruto completo |

Os CSVs usam UTF-8 com BOM, separador `;` e vírgula decimal, para abrir direto no Excel em pt-BR.

## Esquema dos eventos

Toda linha tem `jogador`, `sessao`, `momento` (data/hora local), `t_sessao` (s desde o início),
`fase`, `zona`, `x`, `y` (posição do Garibot) e `evento`. Campos extras por evento:

| Evento | Campos |
|---|---|
| `sessao_inicio` / `sessao_fim` | versao, esquema, plataforma, idioma, resolucao, build_debug / duracao_s |
| `preferencia_inicial` | chave, valor |
| `preferencia_alterada` | chave, antes, depois (mudanças contínuas de slider viram um evento) |
| `dialogo_inicio` / `dialogo_fim` | timeline / timeline, duracao_s, falas |
| `fala` | timeline, personagem, texto |
| `resposta` | timeline, personagem, pergunta, alternativas, escolhida, resultado (`certa`, `errada`, `ouvir_de_novo`), tentativa, tempo_resposta_s |
| `minigame_inicio` / `minigame_fim` | atividade / atividade, perfeito, duracao_s |
| `minigame_resposta` / `minigame_pulou` | atividade, correta / atividade |
| `fase_inicio`, `zona_entrou`, `queda_rio`, `renascimento` | (só as colunas comuns) |
| `reee_coletado` | item, total |
| `dano` | quantidade, fonte (`patrulha`, `pilha_corroida`, `eletrolito`, `poca_acida`, `contato`), bateria |
| `morte` | mortes |
| `inimigo_derrotado` | tipo |
| `pausa_aberta` / `pausa_fechada` | — / duracao_s |
| `fase_concluida` | tempo_total_s, mortes |

O acerto das perguntas vem do diálogo:
- **Certa:** a alternativa certa emite `[signal arg="acerto"]`.
- **Errada:** a pergunta reaparece ou o diálogo termina.
- **Ouvir de novo:** a alternativa tem esse texto exato.

Novos eventos: `Analytics.track("nome", {"campo": valor})`. Eles entram automaticamente na aba
"Eventos". Para outra aba, inclua o evento em `EVENT_SHEETS` (`analytics_exporter.gd`).

## Envio remoto (jogo publicado)

Arquivos locais ficam na máquina de cada jogador. Para juntar os dados de todos, configure
`REMOTE_URL`. Os eventos são enviados em lotes (POST JSON `{"rows": [...]}`, a cada 25 eventos
ou 30 s). Sem internet, ficam em `user://analytics/pending.jsonl` e são reenviados depois.
O envio só acontece com a preferência **"Compartilhar dados anônimos de uso"** ligada.

### Opção simples: Google Planilha + Apps Script

1. Crie uma Google Planilha. Em **Extensões → Apps Script**, cole:

```javascript
function doPost(e) {
  const rows = JSON.parse(e.postData.contents).rows || [];
  const sheet = SpreadsheetApp.getActive().getSheetByName("Eventos")
    || SpreadsheetApp.getActive().insertSheet("Eventos");
  let header = sheet.getLastRow() > 0
    ? sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0] : [];
  rows.forEach(r => Object.keys(r).forEach(k => { if (!header.includes(k)) header.push(k); }));
  sheet.getRange(1, 1, 1, header.length).setValues([header]);
  const values = rows.map(r => header.map(k => r[k] === undefined ? "" : r[k]));
  if (values.length) sheet.getRange(sheet.getLastRow() + 1, 1, values.length, header.length).setValues(values);
  return ContentService.createTextOutput("ok");
}
```

2. **Implantar → Nova implantação → App da Web**. Executar como: você. Acesso: qualquer pessoa.
3. Copie a URL `https://script.google.com/macros/s/.../exec` para `REMOTE_URL`.

Para volumes maiores, use Supabase/PostgreSQL ou um endpoint próprio. O formato do POST é o mesmo.

## Privacidade (público infantil / LGPD)

- **Dados guardados:** só um ID aleatório gerado no aparelho, sem nome, e-mail ou outro dado pessoal. O jogo não grava IP; um servidor remoto pode registrá-lo nos próprios logs.
- **Antes de publicar com envio remoto:**
  - obtenha o consentimento dos responsáveis ou da escola;
  - explique na página do jogo quais dados são coletados e para quê;
  - mantenha a opção de desligar nas configurações.
