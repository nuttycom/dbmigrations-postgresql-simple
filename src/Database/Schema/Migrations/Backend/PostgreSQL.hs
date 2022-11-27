{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Database.Schema.Migrations.Backend.PostgreSQL
  ( backend,
  )
where

import Data.Functor (void)
import Data.String (fromString)
import Data.String.Conversions (cs)
import Data.Text (Text)
import Data.Time.Clock (getCurrentTime)
import qualified Database.PostgreSQL.Simple as PG
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.FromRow (field)
import Database.PostgreSQL.Simple.SqlQQ (sql)
import qualified Database.PostgreSQL.Simple.Transaction as PG
import Database.Schema.Migrations.Backend
  ( Backend (..),
    rootMigrationName,
  )
import Database.Schema.Migrations.Migration
  ( Migration (..),
    newMigration,
  )

migrationTableName :: Text
migrationTableName = "installed_migrations"

createSql :: Text
createSql = "CREATE TABLE " <> migrationTableName <> " (migration_id TEXT)"

revertSql :: Text
revertSql = "DROP TABLE " <> migrationTableName

getTables :: PG.Connection -> IO [Text]
getTables conn =
  PG.queryWith_
    field
    conn
    [sql| SELECT table_name FROM information_schema.tables
          WHERE table_schema != 'pg_catalog'
          AND table_schema != 'information_schema' |]

-- | Backend constructor for Database.PostgreSQL.Simple
backend :: PG.Connection -> Backend
backend conn =
  Backend
    { isBootstrapped = elem migrationTableName <$> getTables conn,
      getBootstrapMigration =
        do
          ts <- getCurrentTime
          pure $
            (newMigration rootMigrationName)
              { mApply = createSql,
                mRevert = Just revertSql,
                mDesc = Just "Migration table installation",
                mTimestamp = Just ts
              },
      applyMigration = \m -> do
        PG.execute_ conn (fromString . cs $ mApply m)
        let qins = "INSERT INTO " <> (cs migrationTableName) <> " (migration_id) VALUES (?)"
        void $ PG.execute conn (fromString qins) (PG.Only $ mId m),
      revertMigration = \m -> do
        case mRevert m of
          Nothing -> pure ()
          Just q -> void $ PG.execute_ conn (fromString . cs $ q)
        -- Remove migration from installed_migrations in either case.
        let qdel = "DELETE FROM " <> (cs migrationTableName) <> " WHERE migration_id = ?"
        void $ PG.execute conn (fromString qdel) (PG.Only $ mId m),
      getMigrations =
        PG.queryWith_ field conn (fromString $ "SELECT migration_id FROM " <> (cs migrationTableName)),
      commitBackend = PG.commit conn,
      rollbackBackend = PG.rollback conn,
      disconnectBackend = PG.close conn
    }
