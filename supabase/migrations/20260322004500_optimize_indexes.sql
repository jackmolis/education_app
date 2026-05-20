-- Global Database High-Performance Query Vectors
-- Mapping explicit B-Tree indexing constraints drastically reducing standard implicit memory-sweeps on strictly fetched aggregate arrays.

-- Lessons Relationship Query Accelerator
CREATE INDEX IF NOT EXISTS idx_lessons_subject_id ON lessons (subject_id);
CREATE INDEX IF NOT EXISTS idx_lessons_order_number ON lessons (order_number);

-- Quizzes Relationship Resolving Allocator
CREATE INDEX IF NOT EXISTS idx_quizzes_lesson_id ON quizzes (lesson_id);

-- Profile Analytic Fast Arrays 
CREATE INDEX IF NOT EXISTS idx_results_user_id ON results (user_id);
CREATE INDEX IF NOT EXISTS idx_progress_user_id ON user_progress (user_id);

-- Complex Join Resolvers over Student Data
CREATE INDEX IF NOT EXISTS idx_results_lesson_id ON results (lesson_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson_id ON user_progress (lesson_id);
