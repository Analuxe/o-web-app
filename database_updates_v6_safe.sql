-- Safe Schema Migration Script (v6)
-- 1. Online Status (from v3)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_online boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS last_active timestamp with time zone;

-- 2. Profile Views (from v4)
CREATE TABLE IF NOT EXISTS public.profile_views (
    viewer_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    viewed_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    viewed_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (viewer_id, viewed_id)
);
ALTER TABLE public.profile_views ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can see who viewed them" ON public.profile_views;
DROP POLICY IF EXISTS "Users can log their views" ON public.profile_views;
CREATE POLICY "Users can see who viewed them" ON public.profile_views FOR SELECT USING (auth.uid() = viewed_id);
CREATE POLICY "Users can log their views" ON public.profile_views FOR INSERT WITH CHECK (auth.uid() = viewer_id);

-- 3. Reputation Reports (from v4)
CREATE TABLE IF NOT EXISTS public.reputation_reports (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    target_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(reporter_id, target_id)
);
ALTER TABLE public.reputation_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can view reputation reports" ON public.reputation_reports;
DROP POLICY IF EXISTS "Users can submit reputation reports" ON public.reputation_reports;
CREATE POLICY "Admins can view reputation reports" ON public.reputation_reports FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true));
CREATE POLICY "Users can submit reputation reports" ON public.reputation_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- 4. Premium Flag (from v4)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_premium boolean DEFAULT false;

-- 5. Notifications Table (from v4)
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    type text NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System/Admins can create notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System/Admins can create notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- 6. Verification Applications (from v4)
CREATE TABLE IF NOT EXISTS public.verification_applications (
    user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    id_image_url text NOT NULL,
    status text DEFAULT 'pending',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
ALTER TABLE public.verification_applications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own application" ON public.verification_applications;
DROP POLICY IF EXISTS "Admins can view all applications" ON public.verification_applications;
CREATE POLICY "Users can view their own application" ON public.verification_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all applications" ON public.verification_applications FOR SELECT USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true));

-- 7. Endorsements (from v5)
CREATE TABLE IF NOT EXISTS public.endorsements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    endorser_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    endorsed_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(endorser_id, endorsed_id)
);
ALTER TABLE public.endorsements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view approved endorsements" ON public.endorsements;
DROP POLICY IF EXISTS "Users can view pending endorsements sent to them" ON public.endorsements;
DROP POLICY IF EXISTS "Users can create endorsements" ON public.endorsements;
DROP POLICY IF EXISTS "Users can update endorsements sent to them" ON public.endorsements;
DROP POLICY IF EXISTS "Users can delete their own endorsements" ON public.endorsements;

CREATE POLICY "Users can view approved endorsements" ON public.endorsements FOR SELECT USING (status = 'approved');
CREATE POLICY "Users can view pending endorsements sent to them" ON public.endorsements FOR SELECT USING (auth.uid() = endorsed_id OR auth.uid() = endorser_id);
CREATE POLICY "Users can create endorsements" ON public.endorsements FOR INSERT WITH CHECK (auth.uid() = endorser_id);
CREATE POLICY "Users can update endorsements sent to them" ON public.endorsements FOR UPDATE USING (auth.uid() = endorsed_id);
CREATE POLICY "Users can delete their own endorsements" ON public.endorsements FOR DELETE USING (auth.uid() = endorser_id OR auth.uid() = endorsed_id);

-- 8. Reload Schema Cache (Fix for PGRST204/PGRST205 errors)
NOTIFY pgrst, 'reload schema';
