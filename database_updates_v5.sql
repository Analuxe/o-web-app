-- Endorsements Table
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

CREATE POLICY "Users can view approved endorsements" ON public.endorsements
    FOR SELECT USING (status = 'approved');

CREATE POLICY "Users can view pending endorsements sent to them" ON public.endorsements
    FOR SELECT USING (auth.uid() = endorsed_id OR auth.uid() = endorser_id);

CREATE POLICY "Users can create endorsements" ON public.endorsements
    FOR INSERT WITH CHECK (auth.uid() = endorser_id);

CREATE POLICY "Users can update endorsements sent to them" ON public.endorsements
    FOR UPDATE USING (auth.uid() = endorsed_id);

CREATE POLICY "Users can delete their own endorsements" ON public.endorsements
    FOR DELETE USING (auth.uid() = endorser_id OR auth.uid() = endorsed_id);

