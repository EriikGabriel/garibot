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
