-- Disable RLS for communications table (like other tables in the system)

-- Drop existing policies
DROP POLICY IF EXISTS "Admin full access" ON communications;
DROP POLICY IF EXISTS "Users can view their communications" ON communications;
DROP POLICY IF EXISTS "Users can mark as read" ON communications;

-- Disable RLS completely
ALTER TABLE communications DISABLE ROW LEVEL SECURITY;

-- Alternative: Enable RLS but with permissive policies for all authenticated users
-- ALTER TABLE communications ENABLE ROW LEVEL SECURITY;
-- 
-- CREATE POLICY "Allow all for authenticated users" ON communications
--     FOR ALL
--     TO authenticated
--     USING (true)
--     WITH CHECK (true);
