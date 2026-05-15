-- Run this in your Supabase SQL Editor to support User Online Status
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_online boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS last_active timestamp with time zone;
