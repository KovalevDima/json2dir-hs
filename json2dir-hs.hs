{-# LANGUAGE OverloadedStrings #-}
module Main where

import Data.Aeson
import Data.Aeson.Key (toString)
import Data.Aeson.KeyMap qualified as KM (toList)
import Data.ByteString.Lazy.Char8 qualified as BS8
import Data.Text qualified as Text
import Data.Text.IO as Text (writeFile)
import GHC.Exts (toList)
import System.Directory
import System.FilePath
import System.IO
import Data.Text (Text)

main = do
  maybeJson <- decode @Value <$> BS8.hGetContents stdin
  
  case maybeJson of
    Nothing -> error "Error. Failed to parse JSON."
    Just json -> toDir json

toDir :: Value -> IO ()
toDir json = goToDir "." json
  where
  goToDir :: FilePath -> Value -> IO ()
  goToDir currentPath (Object objMap) = do
    let obj = toList objMap
    if null obj
    then goToDir currentPath (String mempty)
    else mapM_ (\(key, subJson) -> goToDir (currentPath </> toString key) subJson) obj
  goToDir currentPath (Array arr) = do
    case toList arr of
      "link"  :(String filename): _ -> createFileLink currentPath (Text.unpack filename)
      "script":(String content) : _ -> goToDir currentPath (String content)
      _                             -> mapM_ (goToDir currentPath) arr
  goToDir currentPath (String text) = writeFileText currentPath text
  goToDir currentPath (Number num) = writeFileString currentPath (show num)
  goToDir currentPath (Bool bool) = writeFileString currentPath (show bool)
  goToDir currentPath (Null) = writeFileString currentPath (show Null)

writeFileText :: FilePath -> Text -> IO ()
writeFileText path txt = do
  createDirectoryIfMissing True (takeDirectory path)
  Text.writeFile path txt

writeFileString :: FilePath -> String -> IO ()
writeFileString path str = do
  createDirectoryIfMissing True (takeDirectory path)
  Prelude.writeFile path str
