-- Run this in the SQL editor of your Supabase dashboard
-- Recommend executing one statement at a time to avoid errors
-- Always verify the output before executing

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create the users table in the public schema
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    first_name TEXT,
    last_name TEXT,
    email TEXT UNIQUE NOT NULL
);

-- Create the folders table
CREATE TABLE IF NOT EXISTS folders (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create the notes table
CREATE TABLE IF NOT EXISTS notes (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    folder_id BIGINT REFERENCES folders(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    has_reminder BOOLEAN DEFAULT FALSE
);

-- Create the reminders table
CREATE TABLE IF NOT EXISTS reminders (
    id BIGSERIAL PRIMARY KEY,
    note_id BIGINT NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reminder_time TIMESTAMPTZ NOT NULL,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_note_id UNIQUE (note_id)
);

-- Function to update the updated_at column for folders and notes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Trigger for folders table
CREATE TRIGGER update_folders_updated_at
BEFORE UPDATE ON folders
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

-- Trigger for notes table
CREATE TRIGGER update_notes_updated_at
BEFORE UPDATE ON notes
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();

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

-- Enable Row Level Security (RLS) on folders
ALTER TABLE folders ENABLE ROW LEVEL SECURITY;

-- Policy: Allow owners to access their folders
CREATE POLICY "Folders access policy" ON folders
    FOR ALL
    USING (user_id = auth.uid());

-- Enable Row Level Security (RLS) on notes
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Policy: Allow owners to access their notes
CREATE POLICY "Notes access policy" ON notes
    FOR ALL
    USING (user_id = auth.uid());

-- Enable Row Level Security (RLS) on reminders
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- Policy: Allow owners to access their reminders
CREATE POLICY "Reminders access policy" ON reminders
    FOR ALL
    USING (user_id = auth.uid());

-- Calculate the total database size in MB (optional)
SELECT
  SUM(pg_database_size(pg_database.datname)) / (1024 * 1024) AS db_size_mb
FROM pg_database;