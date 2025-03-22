drop table if exists contents; 
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS contents (
  id                        SERIAL              PRIMARY KEY,
  uuid                      UUID                UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
  title                     VARCHAR             NOT NULL,
  content                   TEXT                NOT NULL,
  params                    JSONB               NOT NULL,
  banner_image              VARCHAR(255)        NOT NULL,
  created_at                TIMESTAMP           NOT NULL  DEFAULT CURRENT_TIMESTAMP,
  created_by                VARCHAR(255)        NOT NULL,
  updated_at                TIMESTAMP                   ,
  updated_by                VARCHAR(255)                ,
  deleted_at                TIMESTAMP                   ,
  deleted_by                VARCHAR(255)                
);