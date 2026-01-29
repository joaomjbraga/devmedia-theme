# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.0.0] - 2026-01-29

### 🎉 Lançamento Inicial

Primeira versão pública do DevMedia Theme para VS Code.

### ✨ Adicionado

#### Temas

- **DevMedia Dark**:
  - Background principal: `#1F1F1F`
  - Cor destaque: `#6F9A35` (Verde oliva DevMedia)
  - Status bar: `#6F9A35`
  - Sidebar: `#1F2F36`
  - Activity bar: `#1A1A1A`
- **DevMedia Light**:
  - Background principal: `#F0F2F5`
  - Cor destaque: `#6F9A35` (Verde oliva DevMedia)
  - Status bar: `#6F9A35`
  - Sidebar: `#EAECF0`
  - Activity bar: `#E8EAEF`

#### Suporte de Linguagens

Destacamento de sintaxe para:

- **Web**: HTML, CSS, SCSS/SASS
- **JavaScript/TypeScript**: Incluindo ES6+, async/await
- **React**: JSX/TSX com componentes destacados
- **Node.js**: Express, módulos, imports
- **Python**:
  - Decorators (`@decorator`)
  - Self destacado em classes
  - Type hints
- **Java**:
  - Annotations (`@Override`, `@Deprecated`)
  - Classes e interfaces
- **PHP**: Sintaxe moderna
- **SQL/MySQL**: Keywords em negrito, comandos DML/DDL
- **C#/.NET**: Classes, attributes, LINQ
- **Dart/Flutter**: Widgets e componentes
- **Angular/Vue.js**: Templates e diretivas
- **Kotlin**: Data classes, extensions
- **Markdown**: Headings, bold, italic, code blocks, links
- **JSON**: Keys e values diferenciados

#### Elementos de Interface

**Activity Bar**

- Background customizado (`#1A1A1A` dark / `#E8EAEF` light)
- Badge com cor destaque (`#6F9A35`)
- Ícones com cor da marca

**Sidebar**

- Background diferenciado (`#1F2F36` dark / `#EAECF0` light)
- Headers de seção destacados
- Seleção ativa com cor DevMedia (`#6F9A35`)

**Editor**

- Line numbers com destaque ativo (`#6F9A35` dark / `#1F2F36` light)
- Cursor destacado
- Seleção com overlay semi-transparente
- Find/Replace com destaque em verde-lima (`#C9F31D`)
- Bracket matching
- Indent guides ativos

**Terminal**

- Cores ANSI personalizadas
- Background consistente com o tema (`#1A1A1A` dark / `#F0F2F5` light)
- Cores otimizadas para logs

**Status Bar**

- Background na cor principal DevMedia (`#6F9A35`)
- Foreground contrastante (`#1A1A1A` dark / `#FAFBFC` light)
- Modo debugging diferenciado (`#D7840A`)

**Tabs**

- Tab ativo com borda superior na cor destaque (`#6F9A35`)
- Background diferenciado
- Hover states

**Git Decorations**

- Modified: Cyan (`#13ECFF` dark / `#0891B2` light)
- Added: Verde-lima (`#C9F31D` dark / `#6F9A35` light)
- Deleted: Vermelho (`#ef4444` dark / `#DC2626` light)
- Untracked: Verde claro (`#A0F31D` dark / `#84CC16` light)
- Ignored: Cinza (`#6b7280` dark / `#9CA3AF` light)
- Conflicting: Laranja (`#D7840A`)

#### Tokens de Sintaxe

**Tema Dark:**

- Comentários: `#6b7280` (itálico)
- Strings: `#A0F31D` (verde claro)
- Números: `#D7840A` (laranja)
- Keywords: `#C9F31D` (verde-lima, negrito)
- Operadores: `#13ECFF` (cyan)
- Funções: `#13ECFF` (cyan)
- Classes: `#6F9A35` (verde oliva, negrito)
- Constantes: `#C9F31D` (verde-lima)
- Propriedades: `#93c5fd` (azul claro)
- HTML Tags: `#C9F31D`
- HTML Attributes: `#13ECFF`
- CSS Classes: `#6F9A35`
- CSS IDs: `#D7840A`
- JSON Keys: `#13ECFF`

**Tema Light:**

- Comentários: `#6B7280` (itálico)
- Strings: `#16A34A` (verde)
- Números: `#D7840A` (laranja)
- Keywords: `#0369A1` (azul, negrito)
- Operadores: `#0891B2` (cyan)
- Funções: `#6F9A35` (verde oliva)
- Classes: `#D7840A` (laranja, negrito)
- Constantes: `#9333EA` (roxo)
- Propriedades: `#0369A1` (azul)
- HTML Tags: `#0369A1`
- HTML Attributes: `#D7840A`
- CSS Classes: `#6F9A35`
- CSS IDs: `#D7840A`
- JSON Keys: `#0369A1`

#### Recursos Especiais

- **Syntax Highlighting Avançado**:
  - Template literals com expressões
  - RegEx patterns
  - Escape characters
  - Invalid/deprecated code
- **Markdown Completo**:
  - Headings em destaque (`#C9F31D` dark / `#0369A1` light)
  - Bold em laranja (`#D7840A`)
  - Italic em cyan (`#13ECFF` dark / `#0891B2` light)
  - Code blocks em verde claro
  - Links sublinhados em cyan
- **Widgets e Popups**:
  - Autocomplete/IntelliSense
  - Peek view
  - Hover tooltips
  - Notifications
- **Outros**:
  - Breadcrumbs
  - Menus contextuais
  - Input fields
  - Buttons e badges
  - Progress bars
  - Scrollbars customizados

### 📚 Documentação

- README.md
- CHANGELOG.md
- Licença MIT
- Screenshots

### 🎨 Design

- Paleta de cores consistente baseada na identidade visual DevMedia
- Dois temas (Dark e Light) para diferentes preferências e ambientes
- Cores semanticamente significativas (verde para sucesso, vermelho para erro, etc.)
- Verde oliva (`#6F9A35`) como cor principal de destaque
- Verde-lima (`#C9F31D`) para elementos secundários e highlights

---

## [Unreleased]

### 🚧 Em Desenvolvimento

Recursos planejados para versões futuras:

- [ ] Variação de alto contraste
- [ ] Suporte para mais extensões populares
- [ ] Tema para terminal externo
- [ ] Ícones customizados de arquivo
- [ ] Melhorias de acessibilidade
- [ ] Suporte para Jupyter Notebooks
- [ ] Tema para browser DevTools

### 💡 Sugestões da Comunidade

Se você tem sugestões de melhorias, abra uma issue no GitHub!

---

## Formato do Versionamento

Este projeto segue o [Semantic Versioning](https://semver.org/lang/pt-BR/):

- **MAJOR**: Mudanças incompatíveis na API
- **MINOR**: Adição de funcionalidades compatíveis
- **PATCH**: Correções de bugs compatíveis

### Tipos de Mudanças

- **Adicionado**: Novas funcionalidades
- **Modificado**: Mudanças em funcionalidades existentes
- **Depreciado**: Funcionalidades que serão removidas
- **Removido**: Funcionalidades removidas
- **Corrigido**: Correções de bugs
- **Segurança**: Vulnerabilidades corrigidas

---

[1.0.0]: https://github.com/joaomjbraga/devmedia-theme/releases/tag/v1.0.0
[Unreleased]: https://github.com/joaomjbraga/devmedia-theme/compare/v1.0.0...HEAD
