-- Run this in your Supabase SQL Editor to support Multimedia Messaging

-- 1. Add new columns to messages table for attachments
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS media_url text,
ADD COLUMN IF NOT EXISTS media_type text;

-- 2. Create a storage bucket for chat media if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('chat_media', 'chat_media', true) 
ON CONFLICT (id) DO NOTHING;

-- 3. Set up RLS for the chat_media bucket
CREATE POLICY "Chat Media Public Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'chat_media');

CREATE POLICY "Chat Media Authenticated users can upload" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'chat_media' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Chat Media Users can delete" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'chat_media' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);
