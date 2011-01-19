{-# LANGUAGE
    RankNTypes
  , UnicodeSyntax
  #-}
module Data.Bitstream.Generic
    ( Bitstream(..)
    )
    where
import qualified Data.List.Stream as L
import Data.Maybe
import qualified Data.Stream as S
import Prelude hiding ( any, break, concat, elem, filter, foldl, foldr, head
                      , length, map, notElem, null, replicate, reverse, scanr
                      , scanr1, span, tail, zipWith3
                      )
import Prelude.Unicode hiding ((∈), (⧺))

infix  4 ∈, ∋, ∉, ∌, `elem`, `notElem`
infixr 5 ⧺, `append`
infixl 6 ∪, `union`
infixr 6 ∩, `intersect`
infixl 9 !!, ∖, \\, ∆

-- THINKME: consider using numeric-prelude's non-negative numbers
-- instead of Integral n.

class Bitstream α where
    stream   ∷ α → S.Stream Bool
    unstream ∷ S.Stream Bool → α

    empty ∷ α
    empty = unstream (S.stream [])
    {-# INLINE empty #-}

    (∅) ∷ α
    (∅) = empty
    {-# INLINE (∅) #-}

    singleton ∷ Bool → α
    singleton = unstream ∘ S.stream ∘ flip (:) []
    {-# INLINE singleton #-}

    pack ∷ [Bool] → α
    pack = unstream ∘ S.stream
    {-# INLINE pack #-}

    unpack ∷ α → [Bool]
    unpack = S.unstream ∘ stream
    {-# INLINE unpack #-}

    cons ∷ Bool → α → α
    cons = (unstream ∘) ∘ (∘ stream) ∘ S.cons
    {-# INLINE cons #-}

    snoc ∷ α → Bool → α
    snoc = (unstream ∘) ∘ S.snoc . stream
    {-# INLINE snoc #-}

    append ∷ α → α → α
    append = (unstream ∘) ∘ (∘ stream) ∘ S.append ∘ stream
    {-# INLINE append #-}

    (⧺) ∷ α → α → α
    (⧺) = append
    {-# INLINE (⧺) #-}

    head ∷ α → Bool
    head = S.head ∘ stream
    {-# INLINE head #-}

    uncons ∷ α → Maybe (Bool, α)
    uncons α
        | null α    = Nothing
        | otherwise = Just (head α, tail α)
    {-# INLINE uncons #-}

    last ∷ α → Bool
    last = S.last ∘ stream
    {-# INLINE last #-}

    tail ∷ α → α
    tail = unstream ∘ S.tail ∘ stream
    {-# INLINE tail #-}

    init ∷ α → α
    init = unstream ∘ S.init ∘ stream
    {-# INLINE init #-}

    null ∷ α → Bool
    null = S.null ∘ stream
    {-# INLINE null #-}

    length ∷ Num n ⇒ α → n
    length = S.genericLength ∘ stream
    {-# INLINE length #-}

    map ∷ (Bool → Bool) → α → α
    map = (unstream ∘) ∘ (∘ stream) ∘ S.map
    {-# INLINE map #-}

    reverse ∷ α → α
    reverse = foldl' (flip cons) (∅)
    {-# INLINE reverse #-}

    intersperse ∷ Bool → α → α
    intersperse = (unstream ∘) ∘ (∘ stream) ∘ S.intersperse
    {-# INLINE intersperse #-}

    intercalate ∷ α → [α] → α
    intercalate α = S.foldr (⧺) (∅) ∘ S.intersperse α ∘ S.stream
    {-# INLINE intercalate #-}

    transpose ∷ [α] → [α]
    transpose []       = []
    transpose (α:αs)
        | null α       = transpose αs
        | otherwise    = (head α `cons` pack (L.map head αs))
                         : transpose (tail α : L.map tail αs)

    foldl ∷ (β → Bool → β) → β → α → β
    foldl f β = S.foldl f β ∘ stream
    {-# INLINE foldl #-}

    foldl' ∷ (β → Bool → β) → β → α → β
    foldl' f β = S.foldl' f β ∘ stream
    {-# INLINE foldl' #-}

    foldl1 ∷ (Bool → Bool → Bool) → α → Bool
    foldl1 = (∘ stream) ∘ S.foldl1
    {-# INLINE foldl1 #-}

    foldl1' ∷ (Bool → Bool → Bool) → α → Bool
    foldl1' = (∘ stream) ∘ S.foldl1'
    {-# INLINE foldl1' #-}

    foldr ∷ (Bool → β → β) → β → α → β
    foldr f β = S.foldr f β ∘ stream
    {-# INLINE foldr #-}

    foldr1 ∷ (Bool → Bool → Bool) → α → Bool
    foldr1 = (∘ stream) ∘ S.foldr1
    {-# INLINE foldr1 #-}

    concat ∷ [α] → α
    concat = S.foldr (⧺) (∅) ∘ S.stream
    {-# INLINE concat #-}

    concatMap ∷ (Bool → α) → α → α
    concatMap f = foldr (\x y → f x ⧺ y) (∅)
    {-# INLINE concatMap #-}

    and ∷ α → Bool
    and = S.and ∘ stream
    {-# INLINE and #-}

    or ∷ α → Bool
    or = S.or ∘ stream
    {-# INLINE or #-}

    any ∷ (Bool → Bool) → α → Bool
    any = (∘ stream) ∘ S.any
    {-# INLINE any #-}

    all ∷ (Bool → Bool) → α → Bool
    all = (∘ stream) ∘ S.all
    {-# INLINE all #-}

    scanl ∷ (Bool → Bool → Bool) → Bool → α → α
    scanl f β α = unstream (S.scanl f β (S.snoc (stream α) (⊥)))
    {-# INLINE scanl #-}

    scanl1 ∷ (Bool → Bool → Bool) → α → α
    scanl1 f α = unstream (S.scanl1 f (S.snoc (stream α) (⊥)))
    {-# INLINE scanl1 #-}

    scanr ∷ (Bool → Bool → Bool) → Bool → α → α
    scanr f β α
        | null α    = singleton β
        | otherwise = let α' = scanr f β (tail α)
                      in
                        f (head α) (head α') `cons` α'
    {-# INLINE scanr #-}

    scanr1 ∷ (Bool → Bool → Bool) → α → α
    scanr1 f α
        | null α        = α
        | null (tail α) = α
        | otherwise     = let α' = scanr1 f (tail α)
                          in
                            f (head α) (head α') `cons` α'
    {-# INLINE scanr1 #-}

    mapAccumL ∷ (β → Bool → (β, Bool)) → β → α → (β, α)
    mapAccumL f s α
        | null α    = (s, α)
        | otherwise = let (s' , a ) = f s (head α)
                          (s'', α') = mapAccumL f s' (tail α)
                      in
                        (s'', a `cons` α')

    mapAccumR ∷ (β → Bool → (β, Bool)) → β → α → (β, α)
    mapAccumR f s α
        | null α    = (s, α)
        | otherwise = let (s'', a ) = f s' (head α)
                          (s' , α') = mapAccumR f s (tail α)
                      in
                        (s'', a `cons` α')

    iterate ∷ (Bool → Bool) → Bool → α
    iterate = (unstream ∘) ∘ S.iterate
    {-# INLINE iterate #-}

    repeat ∷ Bool → α
    repeat = unstream ∘ S.repeat
    {-# INLINE repeat #-}

    replicate ∷ Integral n ⇒ n → Bool → α
    replicate n a
        | n ≤ 0     = (∅)
        | otherwise = a `cons` replicate (n-1) a
    {-# INLINE replicate #-}

    cycle ∷ α → α
    cycle = unstream ∘ S.cycle ∘ stream
    {-# INLINE cycle #-}

    unfoldr ∷ (β → Maybe (Bool, β)) → β → α
    unfoldr = (unstream ∘) ∘ S.unfoldr
    {-# INLINE unfoldr #-}

    unfoldrN ∷ Integral n ⇒ n → (β → Maybe (Bool, β)) → β → (α, Maybe β)
    unfoldrN n0 f β0 = loop_unfoldrN n0 β0 (∅)
        where
          loop_unfoldrN 0 β α = (α, Just β)
          loop_unfoldrN n β α
              = case f β of
                  Nothing      → (α, Nothing)
                  Just (a, β') → loop_unfoldrN (n-1) β' (α `snoc` a)
    {-# INLINE unfoldrN #-}

    take ∷ Integral n ⇒ n → α → α
    take = (unstream ∘) ∘ (∘ stream) ∘ S.genericTake
    {-# INLINE take #-}

    drop ∷ Integral n ⇒ n → α → α
    drop = (unstream ∘) ∘ (∘ stream) ∘ S.genericDrop
    {-# INLINE drop #-}

    splitAt ∷ Integral n ⇒ n → α → (α, α)
    splitAt n α
        = case S.genericSplitAt n (stream α) of
            (xs, ys)
                → (pack xs, pack ys)
    {-# INLINE splitAt #-}

    takeWhile ∷ (Bool → Bool) → α → α
    takeWhile = (unstream ∘) ∘ (∘ stream) ∘ S.takeWhile
    {-# INLINE takeWhile #-}

    dropWhile ∷ (Bool → Bool) → α → α
    dropWhile = (unstream ∘) ∘ (∘ stream) ∘ S.dropWhile
    {-# INLINE dropWhile #-}

    span ∷ (Bool → Bool) → α → (α, α)
    span f α
        | null α     = (α, α)
        | f (head α) = let (β, γ) = span f (tail α)
                       in
                         (head α `cons` β, γ)
        | otherwise  = ((∅), α)

    break ∷ (Bool → Bool) → α → (α, α)
    break f α
        | null α     = (α, α)
        | f (head α) = ((∅), α)
        | otherwise  = let (β, γ) = break f (tail α)
                       in
                         (head α `cons` β, γ)

    group ∷ α → [α]
    group α
        | null α    = []
        | otherwise = let (β, γ) = span (head α ≡) (tail α)
                      in
                        (head α `cons` β) : group γ

    inits ∷ α → [α]
    inits α
        | null α    = α : []
        | otherwise = (∅) : L.map (cons (head α)) (inits (tail α))

    tails ∷ α → [α]
    tails α
        | null α    = α : []
        | otherwise = α : tails (tail α)

    isPrefixOf ∷ α → α → Bool
    isPrefixOf x y = S.isPrefixOf (stream x) (stream y)
    {-# INLINE isPrefixOf #-}

    isSuffixOf ∷ α → α → Bool
    isSuffixOf x y = reverse x `isPrefixOf` reverse y
    {-# INLINE isSuffixOf #-}

    isInfixOf ∷ α → α → Bool
    isInfixOf x y = L.any (x `isPrefixOf`) (tails y)
    {-# INLINE isInfixOf #-}

    elem ∷ Bool → α → Bool
    elem = (∘ stream) ∘ S.elem
    {-# INLINE elem #-}

    (∈) ∷ Bool → α → Bool
    (∈) = elem
    {-# INLINE (∈) #-}

    (∋) ∷ α → Bool → Bool
    (∋) = flip elem
    {-# INLINE (∋) #-}

    notElem ∷ Bool → α → Bool
    notElem = ((¬) ∘) ∘ (∈)
    {-# INLINE notElem #-}

    (∉) ∷ Bool → α → Bool
    (∉) = notElem
    {-# INLINE (∉) #-}

    (∌) ∷ α → Bool → Bool
    (∌) = flip notElem
    {-# INLINE (∌) #-}

    filter ∷ (Bool → Bool) → α → α
    filter = (unstream ∘) ∘ (∘ stream) ∘ S.filter
    {-# INLINE filter #-}

    find ∷ (Bool → Bool) → α → Maybe Bool
    find = (∘ stream) ∘ S.find
    {-# INLINE find #-}

    partition ∷ (Bool → Bool) → α → (α, α)
    partition f α = foldr select ((∅), (∅)) α
        where
          select a ~(β, γ)
              | f a       = (a `cons` β, γ)
              | otherwise = (β, a `cons` γ)

    (!!) ∷ Integral n ⇒ α → n → Bool
    (!!) = S.genericIndex ∘ stream
    {-# INLINE (!!) #-}

    elemIndex ∷ Integral n ⇒ Bool → α → Maybe n
    elemIndex = findIndex ∘ (≡)
    {-# INLINE elemIndex #-}

    elemIndices ∷ Integral n ⇒ Bool → α → [n]
    elemIndices = findIndices ∘ (≡)
    {-# INLINE elemIndices #-}

    findIndex ∷ Integral n ⇒ (Bool → Bool) → α → Maybe n
    findIndex = (listToMaybe ∘) ∘ findIndices
    {-# INLINE findIndex #-}

    findIndices ∷ Integral n ⇒ (Bool → Bool) → α → [n]
    findIndices f = find' 0
        where
          find' n α
              | null α     = []
              | f (head α) = n : find' (n+1) (tail α)
              | otherwise  =     find' (n+1) (tail α)

    zip ∷ α → α → [(Bool, Bool)]
    zip a b = S.unstream (S.zip (stream a) (stream b))
    {-# INLINE zip #-}

    zip3 ∷ α → α → α → [(Bool, Bool, Bool)]
    zip3 = zipWith3 (,,)
    {-# INLINE zip3 #-}

    zip4 ∷ α → α → α → α → [(Bool, Bool, Bool, Bool)]
    zip4 = zipWith4 (,,,)
    {-# INLINE zip4 #-}

    zip5 ∷ α → α → α → α → α → [(Bool, Bool, Bool, Bool, Bool)]
    zip5 = zipWith5 (,,,,)
    {-# INLINE zip5 #-}

    zip6 ∷ α → α → α → α → α → α → [(Bool, Bool, Bool, Bool, Bool, Bool)]
    zip6 = zipWith6 (,,,,,)
    {-# INLINE zip6 #-}

    zip7 ∷ α → α → α → α → α → α → α → [(Bool, Bool, Bool, Bool, Bool, Bool, Bool)]
    zip7 = zipWith7 (,,,,,,)
    {-# INLINE zip7 #-}

    zipWith ∷ (Bool → Bool → β) → α → α → [β]
    zipWith f a b = S.unstream (S.zipWith f
                                     (stream a)
                                     (stream b))
    {-# INLINE zipWith #-}

    zipWith3 ∷ (Bool → Bool → Bool → β) → α → α → α → [β]
    zipWith3 f a b c = S.unstream (S.zipWith3 f
                                        (stream a)
                                        (stream b)
                                        (stream c))
    {-# INLINE zipWith3 #-}

    zipWith4 ∷ (Bool → Bool → Bool → Bool → β) → α → α → α → α → [β]
    zipWith4 f a b c d = S.unstream (S.zipWith4 f
                                          (stream a)
                                          (stream b)
                                          (stream c)
                                          (stream d))
    {-# INLINE zipWith4 #-}

    zipWith5 ∷ (Bool → Bool → Bool → Bool → Bool → β) → α → α → α → α → α → [β]
    zipWith5 p a b c d e
        | null a ∨ null b ∨ null c ∨ null d ∨ null e = []
        | otherwise = p (head a) (head b) (head c) (head d) (head e)
                      : zipWith5 p (tail a) (tail b) (tail c) (tail d) (tail e)

    zipWith6 ∷ (Bool → Bool → Bool → Bool → Bool → Bool → β) → α → α → α → α → α → α → [β]
    zipWith6 p a b c d e f
        | null a ∨ null b ∨ null c ∨ null d ∨ null e ∨ null f = []
        | otherwise = p (head a) (head b) (head c) (head d) (head e) (head f)
                      : zipWith6 p (tail a) (tail b) (tail c) (tail d) (tail e) (tail f)

    zipWith7 ∷ (Bool → Bool → Bool → Bool → Bool → Bool → Bool → β) → α → α → α → α → α → α → α → [β]
    zipWith7 p a b c d e f g
        | null a ∨ null b ∨ null c ∨ null d ∨ null e ∨ null f ∨ null g = []
        | otherwise = p (head a) (head b) (head c) (head d) (head e) (head f) (head g)
                      : zipWith7 p (tail a) (tail b) (tail c) (tail d) (tail e) (tail f) (tail g)

    unzip ∷ [(Bool, Bool)] → (α, α)
    unzip = L.foldr (\(a, b) ~(as, bs) →
                         ( a `cons` as
                         , b `cons` bs )) ((∅), (∅))

    unzip3 ∷ [(Bool, Bool, Bool)] → (α, α, α)
    unzip3 = L.foldr (\(a, b, c) ~(as, bs, cs) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs )) ((∅), (∅), (∅))

    unzip4 ∷ [(Bool, Bool, Bool, Bool)] → (α, α, α, α)
    unzip4 = L.foldr (\(a, b, c, d) ~(as, bs, cs, ds) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs
                          , d `cons` ds )) ((∅), (∅), (∅), (∅))

    unzip5 ∷ [(Bool, Bool, Bool, Bool, Bool)] → (α, α, α, α, α)
    unzip5 = L.foldr (\(a, b, c, d, e) ~(as, bs, cs, ds, es) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs
                          , d `cons` ds
                          , e `cons` es )) ((∅), (∅), (∅), (∅), (∅))

    unzip6 ∷ [(Bool, Bool, Bool, Bool, Bool, Bool)] → (α, α, α, α, α, α)
    unzip6 = L.foldr (\(a, b, c, d, e, f) ~(as, bs, cs, ds, es, fs) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs
                          , d `cons` ds
                          , e `cons` es
                          , f `cons` fs )) ((∅), (∅), (∅), (∅), (∅), (∅))

    unzip7 ∷ [(Bool, Bool, Bool, Bool, Bool, Bool, Bool)] → (α, α, α, α, α, α, α)
    unzip7 = L.foldr (\(a, b, c, d, e, f, g) ~(as, bs, cs, ds, es, fs, gs) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs
                          , d `cons` ds
                          , e `cons` es
                          , f `cons` fs
                          , g `cons` gs )) ((∅), (∅), (∅), (∅), (∅), (∅), (∅))

    nub ∷ α → α
    nub = flip nub' (∅)
        where
          nub' ∷ Bitstream α ⇒ α → α → α
          nub' α α'
              | null α      = α
              | head α ∈ α' = nub' (tail α) α'
              | otherwise   = head α `cons` nub' (tail α) (head α `cons` α')

    delete ∷ Bool → α → α
    delete = deleteBy (≡)
    {-# INLINE delete #-}

    (\\) ∷ α → α → α
    (\\) = foldl (flip delete)
    {-# INLINE (\\) #-}

    (∖) ∷ α → α → α
    (∖) = (\\)
    {-# INLINE (∖) #-}

    union ∷ α → α → α
    union = unionBy (≡)
    {-# INLINE union #-}

    (∪) ∷ α → α → α
    (∪) = union
    {-# INLINE (∪) #-}

    intersect ∷ α → α → α
    intersect = intersectBy (≡)
    {-# INLINE intersect #-}

    (∩) ∷ α → α → α
    (∩) = intersect
    {-# INLINE (∩) #-}

    (∆) ∷ α → α → α
    a ∆ b = (a ∖ b) ∪ (b ∖ a)
    {-# INLINE (∆) #-}

    nubBy ∷ (Bool → Bool → Bool) → α → α
    nubBy f = flip nubBy' (∅)
        where
          nubBy' ∷ Bitstream α ⇒ α → α → α
          nubBy' α α'
              | null α              = α
              | elemBy' (head α) α' = nubBy' (tail α) α'
              | otherwise           = head α `cons` nubBy' (tail α) (head α `cons` α')

          elemBy' ∷ Bitstream α ⇒ Bool → α → Bool
          elemBy' a α
              | null α       = False
              | f a (head α) = True
              | otherwise    = elemBy' a (tail α)

    deleteBy ∷ (Bool → Bool → Bool) → Bool → α → α
    deleteBy f a α
        | null α       = α
        | f a (head α) = tail α
        | otherwise    = head α `cons` deleteBy f a (tail α)

    deleteFirstsBy ∷ (Bool → Bool → Bool) → α → α → α
    deleteFirstsBy = foldl ∘ flip ∘ deleteBy

    unionBy ∷ (Bool → Bool → Bool) → α → α → α
    unionBy f x y = x ⧺ foldl (flip (deleteBy f)) (nubBy f y) x

    intersectBy ∷ (Bool → Bool → Bool) → α → α → α
    intersectBy f x y = filter (\a → any (f a) y) x

    groupBy ∷ (Bool → Bool → Bool) → α → [α]
    groupBy f α
        | null α    = []
        | otherwise = let (β, γ) = span (f (head α)) α
                      in
                        (head α `cons` β) : groupBy f γ

{-# RULES
"Bitstream stream/unstream fusion"
    ∀s. stream (unstream s) = s
"Bitstream stream / List unstream fusion"
    ∀s. stream (S.unstream s) = s
"List stream / Bitstream unstream fusion"
    ∀s. S.stream (unstream s) = s
  #-}