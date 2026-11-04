# Componentes reutilizáveis

Componentes não devem conter referências a uma fase, personagem ou diálogo específico.
Cada pasta reúne a cena base e o script correspondente; as fases instanciam a cena e
configuram o comportamento por propriedades exportadas.

| Pasta | Responsabilidade |
| --- | --- |
| `collectibles/` | Coletáveis por contato e seus grupos configuráveis. |
| `minigames/` | Mecânicas de atividade parametrizáveis, como associação de itens. |
| `ui/` | Elementos visuais reutilizáveis, como o painel de progresso de coleta. |
| `health/`, `hitbox/`, `contact_damage/` | Componentes de combate e vida (`Attack` fica em `hitbox/`). |
| `parallax/` | Camadas de fundo que seguem a câmera e animações de ambiente. |
| `restoration/` | Progresso de limpeza do cenário e arte com versões suja e limpa. |

Conteúdo de narrativa, mapas, listas de itens e objetivos pertence a `levels/<fase>/`.
