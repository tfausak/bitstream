{-# LANGUAGE
    FlexibleContexts
  , OverloadedStrings
  , ScopedTypeVariables
  , UndecidableInstances
  , UnicodeSyntax
  #-}
module Main where
import Control.Monad
import Data.Bitstream (Bitstream, Left)
import qualified Data.Bitstream.Generic as G
import Data.Bitstream.Packet
import qualified Data.Bitstream as B
import qualified Data.ByteString as BS
import Data.ByteString.Char8 ()
import Data.Word
import Prelude.Unicode hiding ((⧺), (∈), (∉))
import System.Exit
import Test.QuickCheck

infixr 0 ⟹
infixr 1 .∧.

(⟹) :: Testable α => Bool -> α -> Property
(⟹) = (==>)

(.∧.) ∷ (Testable α, Testable β) ⇒ α → β → Property
(.∧.) = (.&&.)

main ∷ IO ()
main = mapM_ run tests
    where
      run ∷ Property → IO ()
      run prop
          = do r ← quickCheckResult prop
               case r of
                 Success {}           → return ()
                 GaveUp  {}           → exitFailure
                 Failure {}           → exitFailure
                 NoExpectedFailure {} → exitFailure

instance G.Bitstream (Packet d) ⇒ Arbitrary (Bitstream d) where
    arbitrary = sized $ \ n →
                do xs ← replicateM n arbitrary
                   return (B.pack xs)

instance Arbitrary BS.ByteString where
    arbitrary = sized $ \ n →
                do xs ← replicateM n arbitrary
                   return (BS.unfoldr uncons xs)
        where
          uncons ∷ [Word8] → Maybe (Word8, [Word8])
          uncons []     = Nothing
          uncons (x:xs) = Just (x, xs)

type BitL = Bitstream Left
type BitR = Bitstream Right

tests ∷ [Property]
tests = [ -- ∅
          property $ B.null      ((B.∅) ∷ BitL)
        , property $ B.length    ((B.∅) ∷ BitL) ≡ 0
        , property $ B.pack [] ≡ ((B.∅) ∷ BitL)
        , property $ B.empty   ≡ ((B.∅) ∷ BitL)

        , property $ B.null      ((B.∅) ∷ BitR)
        , property $ B.length    ((B.∅) ∷ BitR) ≡ 0
        , property $ B.pack [] ≡ ((B.∅) ∷ BitR)
        , property $ B.empty   ≡ ((B.∅) ∷ BitR)

          -- singleton
        , property $ \b → B.length (B.singleton b ∷ BitL) ≡ 1
        , property $ \b → B.head   (B.singleton b ∷ BitL) ≡ b
        , property $ \b → B.pack [b] ≡ (B.singleton b ∷ BitL)

        , property $ \b → B.length (B.singleton b ∷ BitR) ≡ 1
        , property $ \b → B.head   (B.singleton b ∷ BitR) ≡ b
        , property $ \b → B.pack [b] ≡ (B.singleton b ∷ BitR)

          -- pack/unpack
        , property $ B.unpack (B.pack []      ∷ BitL) ≡ []
        , property $ B.unpack (B.pack [False] ∷ BitL) ≡ [False]
        , property $ B.unpack (B.pack [True ] ∷ BitL) ≡ [True ]
        , property $ \bs → B.unpack (B.pack bs ∷ BitL) ≡ bs
        , property $ \bs → B.pack (B.unpack (bs ∷ BitL)) ≡ bs

        , property $ B.unpack (B.pack []      ∷ BitR) ≡ []
        , property $ B.unpack (B.pack [False] ∷ BitR) ≡ [False]
        , property $ B.unpack (B.pack [True ] ∷ BitR) ≡ [True ]
        , property $ \bs → B.unpack (B.pack bs ∷ BitR) ≡ bs
        , property $ \bs → B.pack (B.unpack (bs ∷ BitR)) ≡ bs

          -- from/toByteString
        , property $ (B.fromByteString "UNK" ∷ BitL)
                       ≡ B.pack (map n2b [ 1, 0, 1, 0, 1, 0, 1, 0
                                         , 0, 1, 1, 1, 0, 0, 1, 0
                                         , 1, 1, 0, 1, 0, 0, 1, 0 ])
        , property $ \s → B.toByteString (B.fromByteString s ∷ BitL) ≡ s
        , mapSize (⋅ 8) $ \bs → (B.length bs `mod` 8) ≡ 0
                                  ⟹ B.fromByteString (B.toByteString (bs ∷ BitL)) ≡ bs
        ]

n2b ∷ Int → Bool
n2b 0 = False
n2b 1 = True
n2b _ = (⊥)
