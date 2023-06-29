# Nola: Power of Deep Embedding for Later-free Impredicative Invariants

Nola is a library for achieving expressive later-free impredicative invariants
by the power of deep embedding.
It is fully mechanized in [Coq](https://coq.inria.fr/) with the
[Iris](https://iris-project.org/) separation logic framework.

The name Nola comes from *No* *la*ters and a nickname for New Orleans,
Los Angeles, US.

- [Getting Started](#getting-started)
- [Story](#story)
  - [Impredicative invariants](#impredicative-invariants)
  - [Obstacle: Laters](#obstacle-laters)
  - [Solution: Nola](#solution-nola)

## Getting Started

We use [opam](https://opam.ocaml.org/) ver 2.* for package management.

To set up an [opam switch](https://opam.ocaml.org/doc/man/opam-switch.html)
named `nola` and link it to the folder:
```bash
opam switch create nola 5.0.0 # Choose an OCaml version
opam switch link nola .
```

To set up opam repos for Coq and Iris for the current opam switch:
```bash
opam repo add coq-released https://coq.inria.fr/opam/released
opam repo add iris-dev https://gitlab.mpi-sws.org/iris/opam.git
```

To fix development dependencies and compile Coq code:
```bash
make devdep
make -j16 # Choose a job number
```

Or to install as a library locally:
```bash
opam install .
```

To generate and browse a document:
```bash
make viewdoc
```

## Architecture

All the Coq code is in [`nola/`](nola/) and structured as follows:
- [`prelude`](nola/prelude.v) : Prelude
- [`util/`](nola/util/) : General-purpose utilities,
  extending [`stdpp`](https://gitlab.mpi-sws.org/iris/stdpp)
  + [`funext`](nola/util/funext.v) (Function extensionality)
  + [`pred`](nola/util/pred.v) (Predicates),
    [`rel`](nola/util/rel.v) (Relations),
    [`wft`](nola/util/wft.v) (Well-founded types),
    [`list`](nola/util/list.v) (Lists),
    [`nat`](nola/util/nat.v) (Natural numbers),
    [`prod`](nola/util/prod.v) (Modified product)
  + [`hgt`](nola/util/hgt.v) (General height of a tree),
    [`ctx`](nola/util/ctx.v) (Context with unguarded/guarded variables)
- [`iris/`](nola/iris) : Iris libraries
  + [`sintp`](nola/iris/sintp.v) (Strong interpretation)
  + [`upd`](nola/iris/upd.v) (Update),
    [`wp`](nola/iris/wp.v) (Weakest precondition)
  + [`inv`](nola/iris/inv.v) (Invariant),
    [`na_inv`](nola/iris/na_inv.v) (Non-atomic invariant)
- [`examples/`](nola/examples/) : Examples
  + [`heap_lang/`](nola/examples/heap_lang/) : Variant of Iris HeapLang,
    with `Ndnat` (terminating infinite non-determinism) added
  + [`logic/`](nola/examples/logic/) : Nola Showcase Logic
    * [`prop`](nola/examples/logic/prop.v) (Proposition),
      [`subst`](nola/examples/logic/subst.v) (Substitution),
      [`iris`](nola/examples/logic/iris.v) (Iris preliminaries),
      [`intp`](nola/examples/logic/intp.v) (Interpretation),
      [`sintp`](nola/examples/logic/sintp.v) (Strong interpretation)
    * [`facts`](nola/examples/logic/facts.v) (Facts),
      [`adequacy`](nola/examples/logic/adequacy.v) (Adequacy),
      [`inv`](nola/examples/logic/inv.v) (Invariant),
      [`na_inv`](nola/examples/logic/na_inv.v) (Non-atomic invariant)
    * [`verify/`](nola/examples/logic/verify/) (Verification examples)
      - [`vlist`](nola/examples/logic/verify/vlist.v) 
          (Shared mutable list with values)
      - [`strm_base`](nola/examples/logic/verify/strm_base.v),
        [`strm`](nola/examples/logic/verify/strm.v),
        [`na_strm`](nola/examples/logic/verify/strm.v) (Shared mutable stream)
  + [`type/`](nola/examples/type/) : Nola Stratified Type System
    * [`type`](nola/examples/type/type.v) (Type),
      [`subst`](nola/examples/type/subst.v) (Substitution),
      [`iris`](nola/examples/type/iris.v) (Iris preliminaries),
      [`intp`](nola/examples/type/intp.v) (Interpretation),
      [`sintp`](nola/examples/type/sintp.v) (Strong interpretation)
    * [`facts`](nola/examples/type/facts.v) (Facts),
      [`adequacy`](nola/examples/type/adequacy.v) (Adequacy)
    * [`rules/`](nola/examples/type/rules/) (Typing rules)
      - [`subeqv`](nola/examples/type/rules/subeqv.v)
        (Subtyping and type equivalence)

## Story

### Impredicative Invariants

By *impredicative invariants*, we mean various forms of invariants or
protocols expressed by separation-logic propositions, which can flexibly model
or reason about shared mutable state.
Impredicative invariants have been essential in the modern usage of separation
logic, especially [Iris](https://iris-project.org/).

The standard (impredicative) invariant in Iris is `inv N P : iProp`,
which uses the namespace `N` for access.
Iris also uses cancellable invariants and non-atomic invariants.

Also, [RustBelt](https://plv.mpi-sws.org/rustbelt/popl18/) built an Iris library
called the lifetime logic to semantically model borrows of the
[Rust](https://www.rust-lang.org/) programming language as rich impredicative
invariants.
For example, Rust's mutable borrow `&'a mut T` is modeled by an impredicative
invariant called a full borrow `&{α} P : iProp`.
It borrows during the lifetime `α` mutable state expressed by an Iris
proposition `P : iProp`.
This is an advanced form of cancellable invariant.

### Obstacle: Laters

#### Step-Indexing

All the existing separation logics with impredicative invariants,
such as [iCAP](https://www.cs.au.dk/~birke/papers/icap-conf.pdf) and Iris,
resort to *step-indexing*.
It is the technique of layering the logic world with step-indices `0, 1, 2, …: ℕ`,
having notions more defined as the step-index grows.
Why?

Their separation-logic proposition `iProp` is a predicate over an abstract
resource `Res`.
For impredicative invariants, `Res` should be able to model agreement on
propositions.
So they define `Res` as some data type depending on `iProp`.
Naively, they have a domain equation like the following,
which is a *circular* definition:
```
iProp  ≜  Res → Prop     Res  ≜  F iProp
```
So they used step-indexing to make this solvable, like:
```
iProp  ≜  Res → sProp     Res  ≜  F (▶ iProp)
```
Here, `sProp` is a step-indexed proposition `ℕ →anti Prop`
and `▶` delays the definition of a data type by one step-index.

#### Laters in the Way

Sounds fine? But this comes with the cost of the *later modality* `▷`.

Due to `▶` added to `iProp`, we can use impredicative invariants only for
propositions under `▷`, which delays the definition of a proposition by one
step-index.
```
inv N P ={↑N,∅}=> ▷ P ∗ (▷ P ={∅,↑N}=∗ True)
```
This causes significant practical issues, especially for dealing with nested
impredicative invariants.

The later modality `▷` is ill-behaved: it is non-idempotent and doesn't commute with the update modality `|==>`.
Various efforts have been made to get over `▷`, such as
[later credits](https://plv.mpi-sws.org/later-credits/), but difficulties
remain.

More fundamentally, the power to strip off `▷` makes program predicates weaker,
ensuring only safety properties (such as partial correctness) but not liveness
properties (especially, termination and total correctness) of programs.
Indeed, recent studies
[Simuliris](https://dl.acm.org/doi/pdf/10.1145/3498689) and
[Fair Operational Semantics](https://dl.acm.org/doi/pdf/10.1145/3591253),
for example, just gave up impredicative invariants in Iris for reasoning about
rich liveness properties regarding fair scheduling.

### Solution: Nola

Nola proposes a new construction of impredicative invariants,
which is free from the later modality `▷`!

We can enjoy various forms of impredicative invariants, free from cumbersome
later handling and achieving advanced liveness verification.

#### Core Idea: Deep Embedding

To achieve impredicative invariants, Nola uses *deeply embedded*
separation-logic proposition, that is, the data type for the *syntax* `A`
equipped with the semantic *interpretation* `⟦ ⟧ : A → iProp`.
Now we have broken the circular definition because the resource `Res` for a
semantic proposition `iProp` depends just on the syntax `A`, like:
```
iProp  ≜  Res → Prop     Res  ≜  F A     ⟦ ⟧ : A → iProp
```
Easy!
