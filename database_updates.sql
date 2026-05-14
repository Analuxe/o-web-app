-- Run this in your Supabase SQL Editor to support the new Profile Features

-- Add new columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS gallery_urls text[] DEFAULT '{}'::text[],
ADD COLUMN IF NOT EXISTS prompts jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS social_links jsonb DEFAULT '{}'::jsonb;

-- Create a storage bucket for gallery images if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('gallery', 'gallery', true) 
ON CONFLICT (id) DO NOTHING;

-- Set up RLS for the gallery bucket
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'gallery');

CREATE POLICY "Authenticated users can upload gallery photos" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'gallery' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own gallery photos" 
ON storage.objects FOR UPDATE 
WITH CHECK (
  bucket_id = 'gallery' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own gallery photos" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'gallery' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);
