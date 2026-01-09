import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing Supabase URL or Key in environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseKey);

// Health check for Supabase connection
export const testSupabaseConnection = async () => {
  try {
    const { data, error } = await supabase.from('polls').select('count()', { count: 'exact', head: true });
    if (error) {
      console.warn('Supabase connection test warning:', error.message);
      return false;
    }
    console.log('✓ Supabase connected successfully');
    return true;
  } catch (err) {
    console.warn('Supabase connection test failed:', err);
    return false;
  }
};
