import { supabase } from '../supabaseClient';

export interface SupabasePoll {
  id: string;
  question: string;
  duration: number;
  status: 'OPEN' | 'CLOSED';
  created_at: string;
  updated_at: string;
}

export interface SupabaseOption {
  id: string;
  poll_id: string;
  text: string;
  is_correct: boolean;
  created_at: string;
}

export interface SupabaseVote {
  id: string;
  poll_id: string;
  student_name: string;
  option_id: string;
  created_at: string;
}

export class SupabasePollService {
  /**
   * Create a new poll in Supabase (parallel to Prisma)
   */
  async createPoll(data: {
    question: string;
    duration: number;
    options: { text: string; isCorrect?: boolean }[];
  }): Promise<SupabasePoll | null> {
    try {
      // Close any existing open polls
      const { error: updateError } = await supabase
        .from('polls')
        .update({ status: 'CLOSED' })
        .eq('status', 'OPEN');

      if (updateError) {
        console.warn('Supabase: Error closing previous polls:', updateError);
      }

      // Create new poll
      const { data: poll, error: pollError } = await supabase
        .from('polls')
        .insert({
          question: data.question,
          duration: data.duration,
          status: 'OPEN',
        })
        .select()
        .single();

      if (pollError || !poll) {
        console.warn('Supabase: Error creating poll:', pollError);
        return null;
      }

      // Create options
      const optionsData = data.options.map((opt) => ({
        poll_id: poll.id,
        text: opt.text,
        is_correct: opt.isCorrect || false,
      }));

      const { error: optionsError } = await supabase
        .from('options')
        .insert(optionsData);

      if (optionsError) {
        console.warn('Supabase: Error creating options:', optionsError);
      }

      return poll;
    } catch (error) {
      console.warn('Supabase: Unexpected error in createPoll:', error);
      return null;
    }
  }

  /**
   * Get active poll from Supabase
   */
  async getActivePoll(): Promise<SupabasePoll | null> {
    try {
      const { data, error } = await supabase
        .from('polls')
        .select('*')
        .eq('status', 'OPEN')
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (error) {
        console.warn('Supabase: Error fetching active poll:', error.message);
        return null;
      }

      return data as SupabasePoll;
    } catch (error) {
      console.warn('Supabase: Unexpected error in getActivePoll:', error);
      return null;
    }
  }

  /**
   * Get poll history from Supabase
   */
  async getPollHistory(): Promise<SupabasePoll[]> {
    try {
      const { data, error } = await supabase
        .from('polls')
        .select('*')
        .eq('status', 'CLOSED')
        .order('created_at', { ascending: false });

      if (error) {
        console.warn('Supabase: Error fetching poll history:', error);
        return [];
      }

      return (data as SupabasePoll[]) || [];
    } catch (error) {
      console.warn('Supabase: Unexpected error in getPollHistory:', error);
      return [];
    }
  }

  /**
   * Get options with vote counts for a poll
   */
  async getOptionsWithVotes(pollId: string): Promise<any[]> {
    try {
      const { data, error } = await supabase
        .from('options')
        .select('*, votes(count)')
        .eq('poll_id', pollId);

      if (error) {
        console.warn('Supabase: Error fetching options:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.warn('Supabase: Unexpected error in getOptionsWithVotes:', error);
      return [];
    }
  }
}

export class SupabaseVoteService {
  /**
   * Submit a vote to Supabase (parallel to Prisma)
   */
  async submitVote(data: {
    pollId: string;
    studentName: string;
    optionId: string;
  }): Promise<SupabaseVote | null> {
    try {
      // Check if poll is open
      const { data: poll, error: pollError } = await supabase
        .from('polls')
        .select('status')
        .eq('id', data.pollId)
        .single();

      if (pollError || !poll || poll.status !== 'OPEN') {
        console.warn('Supabase: Poll is not active or not found');
        return null;
      }

      // Check if student already voted
      const { data: existingVote, error: checkError } = await supabase
        .from('votes')
        .select('id')
        .eq('poll_id', data.pollId)
        .eq('student_name', data.studentName)
        .limit(1)
        .maybeSingle();

      if (existingVote) {
        console.warn('Supabase: Student already voted for this poll');
        return null;
      }

      // Create vote
      const { data: vote, error: voteError } = await supabase
        .from('votes')
        .insert({
          poll_id: data.pollId,
          student_name: data.studentName,
          option_id: data.optionId,
        })
        .select()
        .single();

      if (voteError || !vote) {
        console.warn('Supabase: Error creating vote:', voteError);
        return null;
      }

      return vote as SupabaseVote;
    } catch (error) {
      console.warn('Supabase: Unexpected error in submitVote:', error);
      return null;
    }
  }

  /**
   * Get vote count for an option
   */
  async getOptionVoteCount(optionId: string): Promise<number> {
    try {
      const { count, error } = await supabase
        .from('votes')
        .select('*', { count: 'exact', head: true })
        .eq('option_id', optionId);

      if (error) {
        console.warn('Supabase: Error fetching vote count:', error);
        return 0;
      }

      return count || 0;
    } catch (error) {
      console.warn('Supabase: Unexpected error in getOptionVoteCount:', error);
      return 0;
    }
  }
}
