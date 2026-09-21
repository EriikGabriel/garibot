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

cell_size controla o tamanho mínimo das casas. O tamanho real respeita o
mínimo do campo de texto. A grade tem rolagem e acompanha o foco do teclado.
Chame check_answers() no botão Verificar e conecte completed para avançar.
Inclua arquivos JSON na exportação do Godot (filtro de arquivos não recurso: *.json).
