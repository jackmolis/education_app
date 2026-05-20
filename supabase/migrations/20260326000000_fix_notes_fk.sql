-- Fix foreign key constraint for notes table
-- The original constraint referenced subjects(id) incorrectly instead of lessons(id).

ALTER TABLE notes DROP CONSTRAINT IF EXISTS notes_lesson_id_fkey;

ALTER TABLE notes 
  ADD CONSTRAINT notes_lesson_id_fkey 
  FOREIGN KEY (lesson_id) 
  REFERENCES lessons(id) 
  ON DELETE CASCADE;
