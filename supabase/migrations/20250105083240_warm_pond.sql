/*
  # Add Credit System

  1. Changes
    - Add credit_limit to profiles table
    - Add credit-related fields to sales table
    - Create credits table for tracking credit payments
*/

-- Add credit limit to profiles
ALTER TABLE profiles
ADD COLUMN credit_limit numeric DEFAULT 0;

-- Add credit fields to sales
ALTER TABLE sales
ADD COLUMN is_credit boolean DEFAULT false,
ADD COLUMN paid boolean DEFAULT true;

-- Create credits table
CREATE TABLE credits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id),
  amount numeric NOT NULL CHECK (amount > 0),
  paid_amount numeric DEFAULT 0 CHECK (paid_amount >= 0),
  created_at timestamptz DEFAULT now(),
  due_date timestamptz NOT NULL
);

-- Enable RLS
ALTER TABLE credits ENABLE ROW LEVEL SECURITY;

-- Credits policies
CREATE POLICY "Users can view their own credits"
  ON credits FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage credits"
  ON credits FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );