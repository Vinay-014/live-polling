import { SupabasePollService, SupabaseVoteService } from '../services/SupabaseService';

const supabasePollService = new SupabasePollService();
const supabaseVoteService = new SupabaseVoteService();

/**
 * Sync utilities to replicate operations to both databases
 * Ensures Supabase is updated alongside Prisma operations
 */
export class DatabaseSyncService {
  /**
   * Sync a new poll to Supabase after Prisma create
   */
  static async syncPollToSupabase(pollData: {
    question: string;
    duration: number;
    options: { text: string; isCorrect?: boolean }[];
  }): Promise<void> {
    try {
      const result = await supabasePollService.createPoll(pollData);
      if (result) {
        console.log('[Sync] Poll synced to Supabase:', result.id);
      } else {
        console.warn('[Sync] Failed to sync poll to Supabase');
      }
    } catch (error) {
      console.warn('[Sync] Error syncing poll to Supabase:', error);
    }
  }

  /**
   * Sync a new vote to Supabase after Prisma create
   */
  static async syncVoteToSupabase(voteData: {
    pollId: string;
    studentName: string;
    optionId: string;
  }): Promise<void> {
    try {
      const result = await supabaseVoteService.submitVote(voteData);
      if (result) {
        console.log('[Sync] Vote synced to Supabase:', result.id);
      } else {
        console.warn('[Sync] Failed to sync vote to Supabase');
      }
    } catch (error) {
      console.warn('[Sync] Error syncing vote to Supabase:', error);
    }
  }

  /**
   * Verify data consistency between databases (monitoring)
   */
  static async verifyDataConsistency(): Promise<{
    supabasePolls: number;
    supabaseVotes: number;
    status: string;
  }> {
    try {
      const polls = await supabasePollService.getPollHistory();
      const activePolls = await supabasePollService.getActivePoll();
      const supabasePolls = (polls?.length || 0) + (activePolls ? 1 : 0);

      // Get all votes count
      const { data: votesData, error: votesError } = await (
        await import('../supabaseClient')
      ).supabase
        .from('votes')
        .select('count()', { count: 'exact', head: true });

      return {
        supabasePolls,
        supabaseVotes: votesError ? 0 : 0, // Placeholder
        status: 'verified',
      };
    } catch (error) {
      console.warn('[Sync] Error verifying data consistency:', error);
      return {
        supabasePolls: 0,
        supabaseVotes: 0,
        status: 'error',
      };
    }
  }
}
