/// Centralized image asset paths.
///
/// All paths reference PNGs in `assets/images/`. Drop the generated
/// images there and they will be picked up by the Flutter asset bundle.
class AppImages {
  AppImages._();

  // ── Mascot ──────────────────────────────────────────────────────────
  static const mascotWelcome = 'assets/images/mascot/mascot_welcome.png';
  static const mascotAnalyze = 'assets/images/mascot/mascot_analyze.png';
  static const mascotCelebrate = 'assets/images/mascot/mascot_celebrate.png';
  static const mascotSpeak = 'assets/images/mascot/mascot_speak.png';
  static const mascotPremium = 'assets/images/mascot/mascot_premium.png';
  static const mascotEmpty = 'assets/images/mascot/mascot_empty.png';
  static const mascotError = 'assets/images/mascot/mascot_error.png';

  // ── Mascot States (Speechy) ─────────────────────────────────────────
  static const mascotHappy = 'assets/images/mascot/mascot_happy.png';
  static const mascotImpressed = 'assets/images/mascot/mascot_impressed.png';
  static const mascotEncouraging = 'assets/images/mascot/mascot_encouraging.png';
  static const mascotCoaching = 'assets/images/mascot/mascot_coaching.png';
  static const mascotThinking = 'assets/images/mascot/mascot_thinking.png';

  // ── AI Characters ───────────────────────────────────────────────────
  static const characterAlex = 'assets/images/characters/character_alex.png';
  static const characterSam = 'assets/images/characters/character_sam.png';
  static const characterMorgan = 'assets/images/characters/character_morgan.png';
  static const characterJordan = 'assets/images/characters/character_jordan.png';
  static const characterRiley = 'assets/images/characters/character_riley.png';
  static const characterKai = 'assets/images/characters/character_kai.png';
  static const characterTaylor = 'assets/images/characters/character_taylor.png';
  static const characterAvery = 'assets/images/characters/character_avery.png';
  static const characterLuna = 'assets/images/characters/character_luna.png';
  static const characterViktor = 'assets/images/characters/character_viktor.png';
  static const characterPriya = 'assets/images/characters/character_priya.png';
  static const characterSage = 'assets/images/characters/character_sage.png';
  static const characterNadia = 'assets/images/characters/character_nadia.png';
  static const characterSunny = 'assets/images/characters/character_sunny.png';
  static const characterDev = 'assets/images/characters/character_dev.png';
  static const characterRio = 'assets/images/characters/character_rio.png';
  static const characterEthan = 'assets/images/characters/character_ethan.png';
  static const characterOmar = 'assets/images/characters/character_omar.png';
  static const characterRex = 'assets/images/characters/character_rex.png';
  static const characterIris = 'assets/images/characters/character_iris.png';
  static const characterJake = 'assets/images/characters/character_jake.png';
  static const characterDrNash = 'assets/images/characters/character_dr_nash.png';
  static const characterMarcus = 'assets/images/characters/character_marcus.png';
  static const characterZoe = 'assets/images/characters/character_zoe.png';
  static const characterMaya = 'assets/images/characters/character_maya.png';
  static const characterLeo = 'assets/images/characters/character_leo.png';
  static const characterElena = 'assets/images/characters/character_elena.png';
  static const characterProfChen = 'assets/images/characters/character_prof_chen.png';
  static const characterAria = 'assets/images/characters/character_aria.png';
  static const characterGrace = 'assets/images/characters/character_grace.png';

  // ── Categories ──────────────────────────────────────────────────────
  static const categoryInterviews = 'assets/images/categories/category_interviews.png';
  static const categoryPresentations = 'assets/images/categories/category_presentations.png';
  static const categoryPublicSpeaking = 'assets/images/categories/category_public_speaking.png';
  static const categoryConversations = 'assets/images/categories/category_conversations.png';
  static const categoryDebates = 'assets/images/categories/category_debates.png';
  static const categoryStorytelling = 'assets/images/categories/category_storytelling.png';
  static const categoryPhoneAnxiety = 'assets/images/categories/category_phone_anxiety.png';
  static const categoryDating = 'assets/images/categories/category_dating.png';
  static const categoryConflict = 'assets/images/categories/category_conflict.png';
  static const categorySocial = 'assets/images/categories/category_social.png';

  /// Map category name → image path for easy lookup.
  static const categoryImageMap = {
    'Interviews': categoryInterviews,
    'Presentations': categoryPresentations,
    'Public Speaking': categoryPublicSpeaking,
    'Conversations': categoryConversations,
    'Debates': categoryDebates,
    'Storytelling': categoryStorytelling,
    'Phone Anxiety': categoryPhoneAnxiety,
    'Dating & Social': categoryDating,
    'Conflict & Boundaries': categoryConflict,
    'Social Situations': categorySocial,
  };

  // ── Track Banners ─────────────────────────────────────────────────────
  static const bannerCareer   = 'assets/images/tracks/career/banner.png';
  static const bannerSocial   = 'assets/images/tracks/social/banner.png';
  static const bannerStage    = 'assets/images/tracks/stage/banner.png';
  static const bannerAnxiety  = 'assets/images/tracks/anxiety/banner.png';
  static const bannerTough    = 'assets/images/tracks/tough/banner.png';
  static const bannerGenz     = 'assets/images/tracks/genz/banner.png';

  static const trackBannerMap = {
    'career_confidence': bannerCareer,
    'social_butterfly':  bannerSocial,
    'stage_ready':       bannerStage,
    'anxiety_buster':    bannerAnxiety,
    'tough_conversations': bannerTough,
    'gen_z_work':        bannerGenz,
  };

  // ── Track Scenarios ────────────────────────────────────────────────────
  /// Map scenario ID → image path for easy lookup.
  static const scenarioImageMap = {
    // Career Confidence (Interview Prep)
    'int_1':  'assets/images/tracks/career/scenario_int_1.png',
    'int_2':  'assets/images/tracks/career/scenario_int_2.png',
    'int_3':  'assets/images/tracks/career/scenario_int_3.png',
    'int_4':  'assets/images/tracks/career/scenario_int_4.png',
    'int_5':  'assets/images/tracks/career/scenario_int_5.png',
    'int_6':  'assets/images/tracks/career/scenario_int_6.png',
    'int_7':  'assets/images/tracks/career/scenario_int_7.png',
    'int_8':  'assets/images/tracks/career/scenario_int_8.png',
    'int_9':  'assets/images/tracks/career/scenario_int_9.png',
    'int_10': 'assets/images/tracks/career/scenario_int_10.png',
    'int_11': 'assets/images/tracks/career/scenario_int_11.png',
    'int_12': 'assets/images/tracks/career/scenario_int_12.png',
    'int_13': 'assets/images/tracks/career/scenario_int_13.png',
    // Social Butterfly
    'social_1':  'assets/images/tracks/social/scenario_social_1.png',
    'social_2':  'assets/images/tracks/social/scenario_social_2.png',
    'social_3':  'assets/images/tracks/social/scenario_social_3.png',
    'social_4':  'assets/images/tracks/social/scenario_social_4.png',
    'social_5':  'assets/images/tracks/social/scenario_social_5.png',
    'social_6':  'assets/images/tracks/social/scenario_social_6.png',
    'social_7':  'assets/images/tracks/social/scenario_social_7.png',
    'social_8':  'assets/images/tracks/social/scenario_social_8.png',
    'social_9':  'assets/images/tracks/social/scenario_social_9.png',
    'social_10': 'assets/images/tracks/social/scenario_social_10.png',
    'social_11': 'assets/images/tracks/social/scenario_social_11.png',
    'social_12': 'assets/images/tracks/social/scenario_social_12.png',
    'social_13': 'assets/images/tracks/social/scenario_social_13.png',
    'social_14': 'assets/images/tracks/social/scenario_social_14.png',
    'social_15': 'assets/images/tracks/social/scenario_social_15.png',
    // Stage Ready (Public Speaking)
    'stage_1':  'assets/images/tracks/stage/scenario_stage_1.png',
    'stage_2':  'assets/images/tracks/stage/scenario_stage_2.png',
    'stage_3':  'assets/images/tracks/stage/scenario_stage_3.png',
    'stage_4':  'assets/images/tracks/stage/scenario_stage_4.png',
    'stage_5':  'assets/images/tracks/stage/scenario_stage_5.png',
    'stage_6':  'assets/images/tracks/stage/scenario_stage_6.png',
    'stage_7':  'assets/images/tracks/stage/scenario_stage_7.png',
    'stage_8':  'assets/images/tracks/stage/scenario_stage_8.png',
    'stage_9':  'assets/images/tracks/stage/scenario_stage_9.png',
    'stage_10': 'assets/images/tracks/stage/scenario_stage_10.png',
    'stage_11': 'assets/images/tracks/stage/scenario_stage_11.png',
    'stage_12': 'assets/images/tracks/stage/scenario_stage_12.png',
    'stage_13': 'assets/images/tracks/stage/scenario_stage_13.png',
    'stage_14': 'assets/images/tracks/stage/scenario_stage_14.png',
    'stage_15': 'assets/images/tracks/stage/scenario_stage_15.png',
    // Anxiety Buster
    'anxiety_1':  'assets/images/tracks/anxiety/scenario_anxiety_1.png',
    'anxiety_2':  'assets/images/tracks/anxiety/scenario_anxiety_2.png',
    'anxiety_3':  'assets/images/tracks/anxiety/scenario_anxiety_3.png',
    'anxiety_4':  'assets/images/tracks/anxiety/scenario_anxiety_4.png',
    'anxiety_5':  'assets/images/tracks/anxiety/scenario_anxiety_5.png',
    'anxiety_6':  'assets/images/tracks/anxiety/scenario_anxiety_6.png',
    'anxiety_7':  'assets/images/tracks/anxiety/scenario_anxiety_7.png',
    'anxiety_8':  'assets/images/tracks/anxiety/scenario_anxiety_8.png',
    'anxiety_9':  'assets/images/tracks/anxiety/scenario_anxiety_9.png',
    'anxiety_10': 'assets/images/tracks/anxiety/scenario_anxiety_10.png',
    'anxiety_11': 'assets/images/tracks/anxiety/scenario_anxiety_11.png',
    'anxiety_12': 'assets/images/tracks/anxiety/scenario_anxiety_12.png',
    'anxiety_13': 'assets/images/tracks/anxiety/scenario_anxiety_13.png',
    'anxiety_14': 'assets/images/tracks/anxiety/scenario_anxiety_14.png',
    'anxiety_15': 'assets/images/tracks/anxiety/scenario_anxiety_15.png',
    // Tough Conversations
    'tough_1':  'assets/images/tracks/tough/scenario_tough_1.png',
    'tough_2':  'assets/images/tracks/tough/scenario_tough_2.png',
    'tough_3':  'assets/images/tracks/tough/scenario_tough_3.png',
    'tough_4':  'assets/images/tracks/tough/scenario_tough_4.png',
    'tough_5':  'assets/images/tracks/tough/scenario_tough_5.png',
    'tough_6':  'assets/images/tracks/tough/scenario_tough_6.png',
    'tough_7':  'assets/images/tracks/tough/scenario_tough_7.png',
    'tough_8':  'assets/images/tracks/tough/scenario_tough_8.png',
    'tough_9':  'assets/images/tracks/tough/scenario_tough_9.png',
    'tough_10': 'assets/images/tracks/tough/scenario_tough_10.png',
    'tough_11': 'assets/images/tracks/tough/scenario_tough_11.png',
    'tough_12': 'assets/images/tracks/tough/scenario_tough_12.png',
    'tough_13': 'assets/images/tracks/tough/scenario_tough_13.png',
    'tough_14': 'assets/images/tracks/tough/scenario_tough_14.png',
    'tough_15': 'assets/images/tracks/tough/scenario_tough_15.png',
    // Gen Z at Work
    'genz_1':  'assets/images/tracks/genz/scenario_genz_1.png',
    'genz_2':  'assets/images/tracks/genz/scenario_genz_2.png',
    'genz_3':  'assets/images/tracks/genz/scenario_genz_3.png',
    'genz_4':  'assets/images/tracks/genz/scenario_genz_4.png',
    'genz_5':  'assets/images/tracks/genz/scenario_genz_5.png',
    'genz_6':  'assets/images/tracks/genz/scenario_genz_6.png',
    'genz_7':  'assets/images/tracks/genz/scenario_genz_7.png',
    'genz_8':  'assets/images/tracks/genz/scenario_genz_8.png',
    'genz_9':  'assets/images/tracks/genz/scenario_genz_9.png',
    'genz_10': 'assets/images/tracks/genz/scenario_genz_10.png',
    'genz_11': 'assets/images/tracks/genz/scenario_genz_11.png',
    'genz_12': 'assets/images/tracks/genz/scenario_genz_12.png',
    'genz_13': 'assets/images/tracks/genz/scenario_genz_13.png',
    'genz_14': 'assets/images/tracks/genz/scenario_genz_14.png',
    'genz_15': 'assets/images/tracks/genz/scenario_genz_15.png',
  };
}
