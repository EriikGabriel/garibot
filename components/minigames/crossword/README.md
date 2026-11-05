# Criar uma cruzadinha

Instancie crossword_board.tscn e configure puzzle_file no Inspector.
Copie levels/phase1/minigames/phase1_minigames/reee_crossword.json para criar outra atividade.
O JSON contém uma lista words com answer (palavra) e clue (pista).

O gerador local normaliza acentos, cruza letras iguais e evita sobreposição
na mesma direção e letras vizinhas indevidas. Não usa API nem rede.
É determinístico e não garante encaixar todas as palavras.
Entradas que não couberem aparecem em um aviso no tabuleiro e no log;
troque ou acrescente palavras com letras em comum para melhorar os encaixes.

Para montar uma grade manual, deixe puzzle_file vazio e preencha entries
no Inspector: answer, clue, start (Vector2i, coluna/linha a partir de zero)
e vertical (bool). Use letras maiúsculas sem acentos e coordenadas positivas.

cell_size controla o tamanho preferido das casas; minimum_cell_size define
o limite de redução para caber no espaço disponível. As dicas usam uma grade
com até maximum_clue_columns colunas (padrão: 2), respeitando clue_minimum_width.
Em telas estreitas, as dicas ficam abaixo do tabuleiro. A rolagem permanece
disponível quando uma cruzadinha maior não cabe sem reduzir a legibilidade.
Os contêineres Layout, Grid e CluePanel/Clues podem ser estilizados na cena
crossword_board.tscn; casas e pistas são preenchidas a partir do puzzle.
Chame check_answers() no botão Verificar e conecte completed para avançar.
Inclua arquivos JSON na exportação do Godot (filtro de arquivos não recurso: *.json).

Estilo (grupo "Estilo" no Inspector): number_color, number_font_size,
cell_top_padding (0 = número sobreposto no canto), active_word_tint,
clue_type_variation e block_type_variation (casas fora das palavras viram
painéis pretos). prefer_landscape transpõe grades mais altas que largas.

# Jornal de fim de fase

components/minigames/newspaper/newspaper_crossword.tscn embala a cruzadinha
num jornal (cabeçalho, manchete com foto e o passatempo). Em cada fase,
instancie a cena e configure newspaper_name, edition, headline, article,
photo, photo_caption, puzzle_title, puzzle_hint e puzzle_file. Ela expõe
check_answers(), select_word(), completed e answer_checked, como a cruzadinha.
A arte vem de tools/ui/build_newspaper.py (fontes em assets/sprites/ui/newspaper/aseprite).
