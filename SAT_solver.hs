-- propositional formula types 
data Formula = Const Bool
    | Prop String
    | Not Formula
    | Or [Formula]
    | And [Formula]
    | Impl Formula Formula
    | Equiv Formula Formula
    deriving (Eq)

-- instantiate the Show type class
instance Show Formula where
    show :: Formula -> String
    show (Const False) = "F"
    show (Const True) = "T"
    show (Prop prop) = prop
    show (Not f) = "~" ++ show f
    show (And f) = "(" ++ join_formulas " & " f ++ ")" -- join AND
    show (Or f) = "(" ++ join_formulas " | " f ++ ")" -- join OR
    show (Impl p q) = "(" ++ show p ++ " -> " ++ show q ++ ")" -- join implications
    show (Equiv p q) = "(" ++ show p ++ " <-> " ++ show q ++ ")" -- join equivalences
-- helper function to join formula lists with a logical operator
join_formulas :: String -> [Formula] -> String
join_formulas _ [] = "" -- empty list returns empty string
join_formulas op (x:xs) = show x ++ join_tail xs -- join compound expressions
  where
    join_tail [] = "" -- no operator needed if end of list
    join_tail (x:xs) = op ++ show x ++ join_tail xs -- add operator and process recursively


-- convert a formula to NNF
toNNF :: Formula -> Formula
toNNF formula = toNNF_aux (move_negation (remove_imp_eq formula)) -- remove implications/equivalences, move negation inside, call the aux

-- recursive helper function to process the formula
toNNF_aux :: Formula -> Formula
toNNF_aux (Const p) = Const p -- T and F stay unchanged
toNNF_aux (Prop p) = Prop p -- atomic propositions stay unchanged
toNNF_aux (And f) = And (map toNNF_aux f) -- process AND
toNNF_aux (Or f) = Or (map toNNF_aux f)-- process OR
toNNF_aux f = f -- already in NNF

-- remove implications and equivalences
remove_imp_eq :: Formula -> Formula
remove_imp_eq (Impl p q) = Or [Not (remove_imp_eq p), remove_imp_eq q] -- p -> q => ~p V q
remove_imp_eq (Equiv p q) = And [remove_imp_eq (Impl p q), remove_imp_eq (Impl q p)] -- p <-> q => (p -> q) & (q -> p)
remove_imp_eq (Not f) = Not (remove_imp_eq f) -- process inside negations
remove_imp_eq (And f) = And (map remove_imp_eq f) -- process inside AND statements
remove_imp_eq (Or f) = Or (map remove_imp_eq f) -- process inside OR statements
remove_imp_eq f = f -- already in NNF

-- move negations inward
move_negation :: Formula -> Formula
move_negation (Const p) = Const p -- T and F stay unchanged
move_negation (Prop p) = Prop p -- atomic propositions stay unchanged
move_negation (Not (Const True)) = Const False -- ~T => F
move_negation (Not (Const False)) = Const True -- ~F => T
move_negation (Not (Prop p)) = Not (Prop p) -- ~p already in NNF
move_negation (Not (Not p)) = move_negation p -- ~~p => p
move_negation (Not (And f)) = Or (map move_negation (map Not f)) -- ~(p & q) => ~p V ~q
move_negation (Not (Or f)) = And (map move_negation (map Not f)) -- ~(p V q) => ~p & ~q
move_negation (And f) = And (map move_negation f) -- process conjunctions recursively
move_negation (Or f) = Or (map move_negation f) -- process disjunctions recursively


-- simplify expressions in NNF
simplify :: Formula -> Formula
simplify (Or []) = Const False -- empty OR always false
simplify (And []) = Const True -- empty AND always true
simplify (Const p) = Const p -- T and F stay unchanged
simplify (Prop p) = Prop p -- atomic propositions stay unchanged
simplify (Not (Const True)) = Const False -- ~T => F
simplify (Not (Const False)) = Const True -- ~F => T
simplify (Or f)
    | any (\p -> Not p `elem` f) f = Const True -- if p and ~p exist in formula, formula equals T (p V ~p => T) 
    | Const True `elem` f = Const True -- if T exists in formula, formula equals T (p V T => T)
    | Const False `elem` f = simplify (Or (filter (/= Const False) f)) -- if F exists in formula, remove F (p V F => p) 
    | length f == 1 = head f -- if only one element is left, return it directly
    | otherwise = let new_formula = Or (remove_duplicates (concat (map flatten_or (map simplify f))))
                  in if new_formula == Or f then new_formula else simplify new_formula -- if flattened expression was unchanged, return it, else, rerun simplify
simplify (And f)
    | any (\p -> Not p `elem` f) f = Const False -- if p and ~p exist in formula, formula equals F (p & ~p => F)
    | Const False `elem` f = Const False -- if F exists in formula, formula equals F (p & F => F)
    | Const True `elem` f = simplify (And (filter (/= Const True) f)) -- if T exists in formula, remove T (p & T => p)
    | length f == 1 = head f -- if only one element is left, return it directly
    | otherwise = let new_formula = And (remove_duplicates (concat (map flatten_and (map simplify f)))) 
                  in if new_formula == And f then new_formula else simplify new_formula -- if flattened expression was unchanged, return it, else, rerun simplify
simplify (Not f) = Not (simplify f) -- simplify NOT recursively
simplify f = f -- already simplified

-- remove duplicate variables, for example (p V p => p)
remove_duplicates :: [Formula] -> [Formula]
remove_duplicates [] = []
remove_duplicates (x:xs)
    | x `elem` xs = remove_duplicates xs -- if x is in tail, skip it
    | otherwise = x : remove_duplicates xs -- else, keep x

-- helper functions to flatten nested OR
flatten_or :: Formula -> [Formula]
flatten_or (Or f) = f -- if it's an OR, extract its elements
flatten_or f = [f] -- else, make it a single element list

-- helper functions to flatten nested AND
flatten_and :: Formula -> [Formula]
flatten_and (And f) = f -- if it's an AND, extract its elements
flatten_and f = [f] -- else, make it a single element list


-- types for tableaux branches and for tableaux
type Branch = [Formula] -- a branch is a list of formulas
type Tableau = [Branch] -- a tableau is a list of branches


-- functions for rule applications
-- apply the rule to the first formula on the branch
apply_and_or :: Branch -> [Branch]
apply_and_or [] = [[]]
apply_and_or (x:xs)
  | and_rule x /= [] = [and_rule x ++ xs] -- if formula expands by AND rule, replace it with its conjuncts
  | or_rule x /= [] = [r : xs | r <- or_rule x] -- if formula expands by OR rule, add a branch for each disjunct
  | otherwise = [x : b | b <- apply_and_or xs] -- else keep it and recurse on the rest

-- take an AND formula and return just the underlying formula 
and_rule :: Formula -> [Formula]
and_rule (And f) = f
and_rule _ = []

-- take an OR formula and return just the underlying formula
or_rule :: Formula -> [Formula]
or_rule (Or f) = f
or_rule _ = []


-- expand the tableau recursively
expand :: Tableau -> Tableau
expand [] = []
expand (x:xs)
  | apply_and_or x /= [x] = expand (apply_and_or x ++ xs) -- if rules modify x, replace it with the new branches
  | otherwise = x : expand xs -- else keep x and recurse on the tail

-- return True if a contradiction is found in a branch
f_rule :: Branch -> Bool
f_rule branch
  | Const False `elem` branch = True -- if F exists in branch, there is a contradiction
  | any contradiction branch = True
  | otherwise = False
  where
    contradiction (Prop p) = Not (Prop p) `elem` branch -- for a positive proposition, see if its negation is in the branch
    contradiction (Not (Prop p)) = Prop p `elem` branch -- for a negative proposition, see if the positive is in the branch
    contradiction _ = False


-- check satisfiability
checkSAT :: Formula -> String
checkSAT formula =
  let transformed = simplify (toNNF formula) -- convert to NNF and simplify
      starting_branch = [transformed] -- initialize branch
      tableau = expand [starting_branch] -- initialize and expand the tableau
      valid_branches = filter (not . f_rule) tableau -- remove branches with contradictions
  in if valid_branches /= []
        then -- remove duplicates if there are any on the first branch (all remaining are valid)
            let unique_branch = remove_duplicates (head valid_branches) 
            in "SAT with " ++ show unique_branch -- if a valid branch exists, formula is satisfiable
       else "UNSAT" -- if no valid branches remain, formula is unsatisfiable
