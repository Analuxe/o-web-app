-- Run this in your Supabase SQL Editor to support Profile Views and Reputation Reports

-- 1. Profile Views Table
CREATE TABLE IF NOT EXISTS public.profile_views (
    viewer_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    viewed_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    viewed_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (viewer_id, viewed_id)
);

-- Enable RLS for profile_views
ALTER TABLE public.profile_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see who viewed them" 
ON public.profile_views FOR SELECT 
USING (auth.uid() = viewed_id);

CREATE POLICY "Users can log their views" 
ON public.profile_views FOR INSERT 
WITH CHECK (auth.uid() = viewer_id);

-- 2. Reputation Reports Table (Thumbs Down)
CREATE TABLE IF NOT EXISTS public.reputation_reports (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    target_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(reporter_id, target_id)
);

-- Enable RLS for reputation_reports
ALTER TABLE public.reputation_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view reputation reports" 
ON public.reputation_reports FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

CREATE POLICY "Users can submit reputation reports" 
ON public.reputation_reports FOR INSERT 
WITH CHECK (auth.uid() = reporter_id);

-- 3. Add is_premium to profiles if missing
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_premium boolean DEFAULT false;

-- 4. Notifications Table (if not exists)
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

-- Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications" 
ON public.notifications FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "System/Admins can create notifications" 
ON public.notifications FOR INSERT 
WITH CHECK (true); -- Usually handled by service role, but for UAT we allow it

-- 5. Verification Applications Table (if not exists)
CREATE TABLE IF NOT EXISTS public.verification_applications (
    user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    id_image_url text NOT NULL,
    status text DEFAULT 'pending', -- pending, approved, rejected
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Enable RLS for verification_applications
ALTER TABLE public.verification_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own application" 
ON public.verification_applications FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all applications" 
ON public.verification_applications FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);
