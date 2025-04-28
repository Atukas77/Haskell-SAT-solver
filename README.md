# Haskell SAT Solver

This project implements a SAT (satisfiability) solver in Haskell using the Tableaux method.  
It checks whether a given propositional logic formula can be made true under some assignment of truth values.

## Features

- Full support for propositional formula types: constants, propositions, negations, conjunctions, disjunctions, implications, and equivalences.
- Negation Normal Form (NNF) transformation.
- Formula simplifications.
- Tableaux method for satisfiability checking with exhaustive rule application.
- Pure functional style: **no IO** operations are used—everything is built with pure functions only.

## How to Clone

```bash
git clone https://github.com/Atukas77/Haskell-SAT-solver
```

## How to Run

Because the project is fully functional (pure functions only) and does not include a `main` function or IO interaction, it should be run manually in GHCi:

1. Open a terminal.
2. Navigate to the folder where you cloned/downloaded the project.
3. Launch GHCi:

   ```bash
   ghci SAT_solver.hs
   ```

4. Once inside GHCi, you can directly call the `checkSAT` function with propositional formulas. Example:

   ```haskell
   checkSAT (Equiv (Prop "q") (Or [Const False, Not (Prop "r")]))
   -- Output: "SAT with [~q,r]"
   ```

### Output Interpretation

- If the formula is satisfiable, `checkSAT` returns `SAT with [...]`, showing one possible combination of truth assignments that satisfy the formula.
- If the formula is unsatisfiable, it returns `UNSAT`.
- If the formula is a tautology (always true, no matter the assignment), it returns `SAT with [T]`.


### Important Notes

- The code expects input formulas to be built using the provided `Formula` type structure.
- No external libraries or modules are used—everything is based on the Haskell standard Prelude.

## Example Usage

```haskell
checkSAT (Not (Or [Const True, And [Prop "p", Not (Prop "r")]]))
-- Output: "UNSAT"
```
