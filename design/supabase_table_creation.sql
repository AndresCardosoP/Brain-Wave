-- Supabase AI is experimental and may produce incorrect answers
-- Always verify the output before executing

-- Create the folders table
create table if not exists
  folders (
    id BIGSERIAL primary key,
    name text not null,
    user_id uuid not null references auth.users (id) on delete cascade,
    created_at TIMESTAMPTZ default now(),
    updated_at TIMESTAMPTZ default now()
  );

-- Create the notes table (if not already created)
create table if not exists
  notes (
    id BIGSERIAL primary key,
    title text not null,
    body text,
    user_id uuid not null references auth.users (id) on delete cascade,
    folder_id bigint references folders (id) on delete set null,
    created_at TIMESTAMPTZ default now(),
    updated_at TIMESTAMPTZ default now(),
    attachment_path text
  );

-- Function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for folders table
CREATE TRIGGER update_folders_updated_at
BEFORE UPDATE ON folders
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
--
---- Trigger for notes table
CREATE TRIGGER update_notes_updated_at
BEFORE UPDATE ON notes
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
--
---- Enable RLS on folders
ALTER TABLE folders ENABLE ROW LEVEL SECURITY;
--
---- Policy: Allow owners to select, insert, update, delete their folders
CREATE POLICY "Folders access policy" ON folders
    FOR ALL
    USING (user_id = auth.uid());
 --Enable RLS on notes
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
--Policy: Allow owners to select, insert, update, delete their notes
CREATE POLICY "Notes access policy" ON notes
    FOR ALL
    USING (user_id = auth.uid());

-- Note: Ensure that the column name for user in notes table matches
-- In your current table, it's named 'user', adjust if necessary
-- Create the users table in the public schema
CREATE TABLE if not exists public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    first_name TEXT,
    last_name TEXT,
    email TEXT UNIQUE NOT NULL
);

-- Ensure the uuid_generate_v4() function is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

select
  sum(pg_database_size(pg_database.datname)) / (1024 * 1024) as db_size_mb
from pg_database;

-- Create the reminders table
CREATE TABLE IF NOT EXISTS reminders (
  id BIGSERIAL PRIMARY KEY,
  note_id BIGINT NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reminder_time TIMESTAMPTZ NOT NULL,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to update the updated_at column for reminders
CREATE OR REPLACE FUNCTION update_reminders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Trigger for reminders table
CREATE TRIGGER update_reminders_updated_at
BEFORE UPDATE ON reminders
FOR EACH ROW
EXECUTE PROCEDURE update_reminders_updated_at();

-- Enable RLS on reminders
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- Policy: Allow owners to select, insert, update, delete their reminders
CREATE POLICY "Reminders access policy" ON reminders
    FOR ALL
    USING (user_id = auth.uid());

-- Add unique constraint to note_id
ALTER TABLE reminders
ADD CONSTRAINT unique_note_id UNIQUE (note_id);

ALTER TABLE notes
ADD COLUMN has_reminder BOOLEAN DEFAULT FALSE;

ALTER TABLE notes
DROP COLUMN attachment_path;