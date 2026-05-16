-- Fix connections RLS policy to allow seeding connections where the current user
-- is either the sender OR receiver (needed for UAT data seeding).
DROP POLICY IF EXISTS "Users can create connections" ON public.connections;
CREATE POLICY "Users can create connections" ON public.connections
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );
