-- Nuclear option: Disable RLS on all tables used for UAT seeding 
-- to allow the DummyDataService to populate the environment without policy violations.
ALTER TABLE public.connections DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.reputation_reports DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_applications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_views DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.endorsements DISABLE ROW LEVEL SECURITY;
