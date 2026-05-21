#!/usr/bin/env python3
"""Generate all app images using Gemini API and compress for mobile.

Usage:
  python tools/generate_images.py --api-key <GEMINI_KEY>
  python tools/generate_images.py --api-key <KEY> --only categories
  python tools/generate_images.py --api-key <KEY> --only characters
  python tools/generate_images.py --api-key <KEY> --only mascots
  python tools/generate_images.py --api-key <KEY> --only scenarios
  python tools/generate_images.py --api-key <KEY> --only career
  python tools/generate_images.py --api-key <KEY> --only social
  python tools/generate_images.py --api-key <KEY> --only stage
  python tools/generate_images.py --api-key <KEY> --only anxiety
  python tools/generate_images.py --api-key <KEY> --only tough
  python tools/generate_images.py --api-key <KEY> --only genz
  python tools/generate_images.py --api-key <KEY> --only banners
  python tools/generate_images.py --compress-only
"""

import argparse
import io
import os
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Style prefix shared by every prompt
# ---------------------------------------------------------------------------
STYLE_PREFIX = (
    "Flat vector illustration, minimal clean design, soft rounded shapes, "
    "Duolingo-style cartoon aesthetic, vibrant but not oversaturated colors, "
    "clean white background, centered composition, no text, no borders, "
    "subject occupies central 65% of canvas with generous white padding on all sides, "
    "safe to display in a rounded rectangle or circle crop without clipping any elements. "
)

# ---------------------------------------------------------------------------
# Image definitions — file paths match AppImages constants exactly
# ---------------------------------------------------------------------------
CATEGORIES = [
    (
        "assets/images/categories/category_interviews.png",
        "A person in a suit sitting across a desk from an interviewer in a bright office, professional job interview scene",
    ),
    (
        "assets/images/categories/category_presentations.png",
        "A confident person standing at a podium with presentation slides behind them, giving a talk",
    ),
    (
        "assets/images/categories/category_public_speaking.png",
        "A person speaking into a microphone on a stage with spotlight, audience silhouettes",
    ),
    (
        "assets/images/categories/category_conversations.png",
        "Two people having a friendly casual conversation at a coffee shop, relaxed vibe",
    ),
    (
        "assets/images/categories/category_debates.png",
        "Two people at podiums facing each other in a debate, speech bubbles in air",
    ),
    (
        "assets/images/categories/category_storytelling.png",
        "A person sitting in an armchair telling a story with magical swirls and book pages floating",
    ),
    (
        "assets/images/categories/category_phone_anxiety.png",
        "A person nervously holding a phone to their ear, small sweat drops, gentle encouragement vibe",
    ),
    (
        "assets/images/categories/category_dating.png",
        "Two people at a small cafe table, first date vibe, warm hearts floating subtly",
    ),
    (
        "assets/images/categories/category_conflict.png",
        "A person standing firm with a confident stance, setting boundaries, shield icon nearby",
    ),
    (
        "assets/images/categories/category_social.png",
        "A group of people at a social gathering mingling, warm party lights, friendly vibe",
    ),
]

CHARACTERS = [
    # --- Original 8 ---
    (
        "assets/images/characters/character_alex.png",
        "Head-and-shoulders portrait of a sharp professional male coach in his 30s, direct confident expression, wearing a blazer, blue accent colors",
    ),
    (
        "assets/images/characters/character_sam.png",
        "Head-and-shoulders portrait of a friendly upbeat person with a big warm smile, casual outfit, green accent colors",
    ),
    (
        "assets/images/characters/character_morgan.png",
        "Head-and-shoulders portrait of a wise experienced mentor in their 50s, thoughtful gentle expression, warm orange accent",
    ),
    (
        "assets/images/characters/character_jordan.png",
        "Head-and-shoulders portrait of an energetic sharp debater in their 20s, excited clever expression, red accent colors",
    ),
    (
        "assets/images/characters/character_riley.png",
        "Head-and-shoulders portrait of a friendly professional interviewer, warm approachable smile, sky blue accent",
    ),
    (
        "assets/images/characters/character_kai.png",
        "Head-and-shoulders portrait of a creative expressive storyteller, whimsical artistic vibe, golden yellow accent",
    ),
    (
        "assets/images/characters/character_taylor.png",
        "Head-and-shoulders portrait of a firm authoritative executive, polished powerful look, gold accent",
    ),
    (
        "assets/images/characters/character_avery.png",
        "Head-and-shoulders portrait of a warm supportive guide, gentle encouraging smile, soft orange accent",
    ),
    # --- 22 New Characters ---
    (
        "assets/images/characters/character_luna.png",
        "Head-and-shoulders portrait of an energetic young female life coach with bright eyes and radiant smile, sporty outfit, bright blue accent colors",
    ),
    (
        "assets/images/characters/character_viktor.png",
        "Head-and-shoulders portrait of a stern disciplined male military trainer in his 40s, buzz cut, serious focused expression, dark grey and navy accent",
    ),
    (
        "assets/images/characters/character_priya.png",
        "Head-and-shoulders portrait of a cheerful Indian female podcast host in her 20s, headphones around neck, curious bright expression, warm orange accent",
    ),
    (
        "assets/images/characters/character_sage.png",
        "Head-and-shoulders portrait of a calm relaxed therapist with gentle knowing smile, casual earth-tone outfit, green accent colors",
    ),
    (
        "assets/images/characters/character_nadia.png",
        "Head-and-shoulders portrait of an articulate female science teacher with glasses, precise confident expression, purple accent colors",
    ),
    (
        "assets/images/characters/character_sunny.png",
        "Head-and-shoulders portrait of a bubbly energetic morning show host with big bright smile, colorful outfit, yellow and orange accent",
    ),
    (
        "assets/images/characters/character_dev.png",
        "Head-and-shoulders portrait of a measured analytical male tech lead in his 30s, neat appearance, calm collected look, blue accent colors",
    ),
    (
        "assets/images/characters/character_rio.png",
        "Head-and-shoulders portrait of an animated quick-witted comedian with a playful mischievous grin, expressive eyes, red and pink accent",
    ),
    (
        "assets/images/characters/character_ethan.png",
        "Head-and-shoulders portrait of a calm serene male meditation guide with peaceful closed-eye smile, minimal zen outfit, teal and mint accent",
    ),
    (
        "assets/images/characters/character_omar.png",
        "Head-and-shoulders portrait of a smooth charming male radio DJ in his 30s with a suave confident smile, headphones, warm orange accent",
    ),
    (
        "assets/images/characters/character_rex.png",
        "Head-and-shoulders portrait of a tough bold male personal trainer with strong jawline and intense motivating expression, athletic wear, red accent",
    ),
    (
        "assets/images/characters/character_iris.png",
        "Head-and-shoulders portrait of a gentle soothing female counselor with soft compassionate expression, kind eyes, lavender and light purple accent",
    ),
    (
        "assets/images/characters/character_jake.png",
        "Head-and-shoulders portrait of a laid-back surfer dude with messy hair and relaxed easygoing grin, tank top, teal and aqua accent",
    ),
    (
        "assets/images/characters/character_dr_nash.png",
        "Head-and-shoulders portrait of a wise male researcher in his 50s with reading glasses and deep thoughtful expression, tweed jacket, dark blue accent",
    ),
    (
        "assets/images/characters/character_marcus.png",
        "Head-and-shoulders portrait of a scholarly patient male professor with warm welcoming expression, bow tie, indigo and blue accent",
    ),
    (
        "assets/images/characters/character_zoe.png",
        "Head-and-shoulders portrait of a young enthusiastic female intern in her early 20s with eager excited expression, bright casual outfit, pink accent",
    ),
    (
        "assets/images/characters/character_maya.png",
        "Head-and-shoulders portrait of a relaxed friendly female bartender with great-listener expression, casual apron, green and mint accent",
    ),
    (
        "assets/images/characters/character_leo.png",
        "Head-and-shoulders portrait of a composed direct male news anchor with polished professional look, suit and tie, sky blue accent",
    ),
    (
        "assets/images/characters/character_elena.png",
        "Head-and-shoulders portrait of a sophisticated tactful female diplomat with elegant confident expression, formal attire, light purple accent",
    ),
    (
        "assets/images/characters/character_prof_chen.png",
        "Head-and-shoulders portrait of a patient informative male university professor in his 60s with kind wise expression, glasses, grey and blue accent",
    ),
    (
        "assets/images/characters/character_aria.png",
        "Head-and-shoulders portrait of a bold driven female startup founder in her 30s with fierce determined expression, modern blazer, red accent",
    ),
    (
        "assets/images/characters/character_grace.png",
        "Head-and-shoulders portrait of a kind nurturing grandmother figure in her 60s with warm loving smile, cozy sweater, soft pink accent",
    ),
]

# Mascots are ordered so that mascot_welcome is generated first (used as
# reference for the rest to keep the character design consistent).
MASCOT_BASE_DESC = "A cute round speech bubble mascot character with small arms and legs"

MASCOTS = [
    (
        "assets/images/mascot/mascot_welcome.png",
        f"{MASCOT_BASE_DESC}, waving hello, cheerful big eyes, friendly smile",
    ),
    (
        "assets/images/mascot/mascot_analyze.png",
        f"Same cute speech bubble mascot holding a magnifying glass, curious thinking expression",
    ),
    (
        "assets/images/mascot/mascot_celebrate.png",
        f"Same cute speech bubble mascot jumping with confetti around it, excited celebration pose",
    ),
    (
        "assets/images/mascot/mascot_speak.png",
        f"Same cute speech bubble mascot with sound waves coming from mouth, speaking pose",
    ),
    (
        "assets/images/mascot/mascot_premium.png",
        f"Same cute speech bubble mascot wearing a small golden crown, premium sparkles",
    ),
    (
        "assets/images/mascot/mascot_empty.png",
        f"Same cute speech bubble mascot looking around with empty hands, slightly confused",
    ),
    (
        "assets/images/mascot/mascot_error.png",
        f"Same cute speech bubble mascot with a small bandage, apologetic sad expression",
    ),
    (
        "assets/images/mascot/mascot_happy.png",
        f"Same cute speech bubble mascot with huge smile and sparkle eyes, radiating joy",
    ),
    (
        "assets/images/mascot/mascot_impressed.png",
        f"Same cute speech bubble mascot with wide surprised eyes, clapping hands, wow expression",
    ),
    (
        "assets/images/mascot/mascot_encouraging.png",
        f"Same cute speech bubble mascot giving thumbs up, supportive warm expression",
    ),
    (
        "assets/images/mascot/mascot_coaching.png",
        f"Same cute speech bubble mascot wearing tiny glasses, pointing at a small board, teacher pose",
    ),
    (
        "assets/images/mascot/mascot_thinking.png",
        f"Same cute speech bubble mascot with hand on chin, thought bubble above head",
    ),
]

SCENARIOS = [
    # --- Career Confidence (Interview Prep) ---
    ("assets/images/tracks/career/scenario_int_1.png", "A person confidently introducing themselves at a desk across from an interviewer, professional office, name tag visible"),
    ("assets/images/tracks/career/scenario_int_2.png", "A person at an interview table with bright eyes and genuine enthusiasm, pointing at a company logo on screen, explaining why they want the job"),
    ("assets/images/tracks/career/scenario_int_3.png", "A person with a timeline document, walking interviewer through career milestones, confident storytelling with a resume in hand"),
    ("assets/images/tracks/career/scenario_int_4.png", "A person reflecting honestly at an interview, thought bubble showing a past mistake with an upward arrow showing growth from it"),
    ("assets/images/tracks/career/scenario_int_5.png", "Two coworkers having a tense conversation at work, one calmly explaining with hand gestures, conflict resolution vibe"),
    ("assets/images/tracks/career/scenario_int_6.png", "A person at an interview admitting a failure with a growth plant icon, honest self-aware expression, turning negative to positive"),
    ("assets/images/tracks/career/scenario_int_7.png", "A person proudly describing a career achievement, golden trophy icon and upward graph floating beside them in an interview setting"),
    ("assets/images/tracks/career/scenario_int_8.png", "A person standing tall with a spotlight on them, star and sparkles, confident hiring pitch moment, why hire me energy"),
    ("assets/images/tracks/career/scenario_int_9.png", "A person in an interview thoughtfully naming a weakness with a growth plant icon, turning negative to positive, self-aware"),
    ("assets/images/tracks/career/scenario_int_10.png", "A person in an interview gesturing to a vision board with a 5-year roadmap, future goals visualized as stepping stones"),
    ("assets/images/tracks/career/scenario_int_11.png", "A person describing leading a team in an interview, small team silhouettes around them, leader icon, collaborative vibe"),
    ("assets/images/tracks/career/scenario_int_12.png", "A person in a rapid-fire interview, multiple question bubbles flying at them, quick confident answers, energetic paced scene"),
    ("assets/images/tracks/career/scenario_int_13.png", "A person at a desk confidently discussing numbers with their boss, salary chart going up, negotiation scene"),
    # --- Social Butterfly ---
    ("assets/images/tracks/social/scenario_social_1.png", "Two strangers sitting at a coffee shop, one starting a friendly chat, warm relaxed vibe, small talk beginning"),
    ("assets/images/tracks/social/scenario_social_2.png", "A person walking into a party, confidently introducing themselves to a group of people, balloons and warm lights"),
    ("assets/images/tracks/social/scenario_social_3.png", "A person giving a genuine warm compliment to someone, hearts floating, both smiling, feel-good vibe"),
    ("assets/images/tracks/social/scenario_social_4.png", "A person stepping into a group conversation at a social gathering, open body language, welcoming group"),
    ("assets/images/tracks/social/scenario_social_5.png", "Two acquaintances making weekend plans together, calendar icon, casual friendly energy, coffee cup"),
    ("assets/images/tracks/social/scenario_social_6.png", "Two old friends reuniting with a warm hug, nostalgia bubbles floating, big smiles, reconnecting after years"),
    ("assets/images/tracks/social/scenario_social_7.png", "Two people at a cozy cafe on a first date, coffee cups, warm candle light, butterflies floating, nervous excitement"),
    ("assets/images/tracks/social/scenario_social_8.png", "A person nervously approaching someone with a rose behind their back, heart floating, asking them out on a date"),
    ("assets/images/tracks/social/scenario_social_9.png", "A person being introduced to their partner's friend group at a casual hangout, warm welcoming scene, nervous smiles"),
    ("assets/images/tracks/social/scenario_social_10.png", "A person at a professional social event, exchanging cards, confident handshake, name badges, cocktail hour"),
    ("assets/images/tracks/social/scenario_social_11.png", "Two people in a silent awkward pause, one confidently breaking it with a smile and a new topic, conversation rescue"),
    ("assets/images/tracks/social/scenario_social_12.png", "Two people at a small table with a timer, speed dating round, quick witty exchange, fun energy"),
    ("assets/images/tracks/social/scenario_social_13.png", "A person calmly standing up to a rude comment at a social event, polite but firm expression, onlookers watching"),
    ("assets/images/tracks/social/scenario_social_14.png", "An adult at a new hobby class or community group, nervously introducing themselves, friendly welcoming crowd"),
    ("assets/images/tracks/social/scenario_social_15.png", "Two people navigating a social media misunderstanding face to face, phone showing chat, calm mature tone"),
    # --- Stage Ready (Public Speaking) ---
    ("assets/images/tracks/stage/scenario_stage_1.png", "A person giving a short confident self-introduction speech, small audience, beginner speaker, warm applause"),
    ("assets/images/tracks/stage/scenario_stage_2.png", "A person raising a glass giving a wedding toast, champagne glasses, flowers, celebration, heartfelt emotion"),
    ("assets/images/tracks/stage/scenario_stage_3.png", "A student at a classroom podium giving a presentation, slides behind them, confident posture, attentive class"),
    ("assets/images/tracks/stage/scenario_stage_4.png", "A person in an elevator giving a quick pitch to a business person, clock showing 30 seconds, elevator pitch energy"),
    ("assets/images/tracks/stage/scenario_stage_5.png", "A person speaking at the front of a team meeting room, colleagues sitting around, confident update presenter"),
    ("assets/images/tracks/stage/scenario_stage_6.png", "A person around a campfire telling an engaging story to a small group, magical floating storybook pages, warm glow"),
    ("assets/images/tracks/stage/scenario_stage_7.png", "A person at a conference panel taking audience questions, microphone, calm composed expert expression"),
    ("assets/images/tracks/stage/scenario_stage_8.png", "A person on stage giving a motivational talk, fire vibe, inspired audience raising fists, energetic speaker"),
    ("assets/images/tracks/stage/scenario_stage_9.png", "A person presenting to investors with a pitch deck slide showing a growth arrow, confident startup pitch scene"),
    ("assets/images/tracks/stage/scenario_stage_10.png", "Two people at podiums in a formal debate, speech bubbles clashing, competitive intellectual energy"),
    ("assets/images/tracks/stage/scenario_stage_11.png", "A person at a large conference keynote podium, big audience silhouette, spotlight, commanding stage presence"),
    ("assets/images/tracks/stage/scenario_stage_12.png", "A person at a podium holding a trophy giving an acceptance speech, spotlight, emotional grateful expression"),
    ("assets/images/tracks/stage/scenario_stage_13.png", "A person sitting at a podcast table with microphone, headphones, live guest appearance, confident articulate expression"),
    ("assets/images/tracks/stage/scenario_stage_14.png", "A person on a round red TED-style stage, giving a passionate talk with powerful hand gestures, large audience"),
    ("assets/images/tracks/stage/scenario_stage_15.png", "A person given an unexpected prompt doing an impromptu speech, lightbulb appearing, quick thinking on feet, crowd watching"),
    # --- Anxiety Buster ---
    ("assets/images/tracks/anxiety/scenario_anxiety_1.png", "A person on the phone with a takeout food menu, pizza icon, deep breath expression, successfully ordering food"),
    ("assets/images/tracks/anxiety/scenario_anxiety_2.png", "A person nervously calling a doctor's office, phone to ear, hospital cross icon, appointment calendar, courage vibe"),
    ("assets/images/tracks/anxiety/scenario_anxiety_3.png", "A person at a store counter returning an item, receipt in hand, calm polite expression, staff helping kindly"),
    ("assets/images/tracks/anxiety/scenario_anxiety_4.png", "A person on a street corner asking a stranger for directions, nervous but brave, stranger pointing helpfully"),
    ("assets/images/tracks/anxiety/scenario_anxiety_5.png", "A person on phone with customer service rep icon, hold music waves, patient determined expression, complaint resolved"),
    ("assets/images/tracks/anxiety/scenario_anxiety_6.png", "A person on their first day at a new job, meeting colleagues, nervous smile, office door with welcome sign"),
    ("assets/images/tracks/anxiety/scenario_anxiety_7.png", "A person sitting in a group discussion circle, raising their hand to share an opinion, supportive group around them"),
    ("assets/images/tracks/anxiety/scenario_anxiety_8.png", "A person surprised by an unexpected question, pause bubble, deep breath icon, then confident thoughtful answer"),
    ("assets/images/tracks/anxiety/scenario_anxiety_9.png", "A person firmly but kindly saying no to a pushy person, gentle stop hand gesture, boundary line, calm energy"),
    ("assets/images/tracks/anxiety/scenario_anxiety_10.png", "A person on a bus or subway making small talk with a nearby passenger, relaxed friendly vibe, transit background"),
    ("assets/images/tracks/anxiety/scenario_anxiety_11.png", "A person performing under spotlight pressure, shaking hands transforming to steady confident ones, courage burst"),
    ("assets/images/tracks/anxiety/scenario_anxiety_12.png", "A person calmly talking to a police officer or authority figure, respectful composed expression, no fear vibe"),
    ("assets/images/tracks/anxiety/scenario_anxiety_13.png", "A person put on the spot in a meeting to answer, blank moment then confident response, supportive colleagues"),
    ("assets/images/tracks/anxiety/scenario_anxiety_14.png", "A person having a scary but important conversation, deep breath, courage icon, turning fear into action"),
    ("assets/images/tracks/anxiety/scenario_anxiety_15.png", "A person staying calm during a crisis or emergency, giving clear instructions, others relying on them, composed leader"),
    # --- Tough Conversations ---
    ("assets/images/tracks/tough/scenario_tough_1.png",
     "A person on a phone or chat sending a message to reschedule dinner plans with a friend, calendar icon and clock, low-stakes request"),
    ("assets/images/tracks/tough/scenario_tough_2.png",
     "A person holding up a gentle hand to a smiling friend, drawn boundary line between them, kind but firm expression"),
    ("assets/images/tracks/tough/scenario_tough_3.png",
     "A person at a desk calmly handing back a stack of extra papers to a colleague, polite no gesture, office setting"),
    ("assets/images/tracks/tough/scenario_tough_4.png",
     "Two friends sitting on a bench, one with a hurt expression sharing feelings, the other listening attentively, empathy vibe"),
    ("assets/images/tracks/tough/scenario_tough_5.png",
     "Two colleagues at a table, one pointing at a work document giving constructive feedback, speech bubble with improvement arrow"),
    ("assets/images/tracks/tough/scenario_tough_6.png",
     "A person standing confidently across a desk from a manager, pushing back calmly with hand gesture, scales of fairness icon"),
    ("assets/images/tracks/tough/scenario_tough_7.png",
     "A person on a video call delivering bad news to a disappointed client on screen, empathetic expression, apology vibe"),
    ("assets/images/tracks/tough/scenario_tough_8.png",
     "Two roommates in a living room, one calmly pointing at a repeated messy area, confronting habitual behavior, clock showing again"),
    ("assets/images/tracks/tough/scenario_tough_9.png",
     "A person standing firm with a gentle smile against a guilt-tripping family member, shield of confidence, boundary line glowing"),
    ("assets/images/tracks/tough/scenario_tough_10.png",
     "A person across a desk from a manager with a salary chart arrow going up, confident ask for a raise, first time nervous energy"),
    ("assets/images/tracks/tough/scenario_tough_11.png",
     "A person telling parents about a big life decision at a family table, parents with surprised expressions, person standing firm with warmth"),
    ("assets/images/tracks/tough/scenario_tough_12.png",
     "Two friends sitting across from each other, one gently ending the friendship with kind clear words, tissue box, bittersweet emotion"),
    ("assets/images/tracks/tough/scenario_tough_13.png",
     "A person at a meeting table disputing a performance review document with a manager, respectful disagreement, red flag on paper"),
    ("assets/images/tracks/tough/scenario_tough_14.png",
     "A person at a hiring desk holding their number firm against a recruiter pushing back, salary figure in speech bubble, confident stance"),
    ("assets/images/tracks/tough/scenario_tough_15.png",
     "A junior person calmly confronting a VP in a large office about credit-stealing, power imbalance visible, small person standing tall"),
    # --- Gen Z at Work ---
    ("assets/images/tracks/genz/scenario_genz_1.png",
     "A young person in an office nervously making a work phone call, phone to ear, deep breath, desk with computer, office environment"),
    ("assets/images/tracks/genz/scenario_genz_2.png",
     "A person on a laptop video call standup introducing themselves, camera on, other faces in grid, raising hand to speak"),
    ("assets/images/tracks/genz/scenario_genz_3.png",
     "Two colleagues in a break room before a meeting, casual small talk over coffee cups, relaxed friendly vibe, pre-meeting chat"),
    ("assets/images/tracks/genz/scenario_genz_4.png",
     "A junior employee asking a senior colleague for help at a shared desk, question mark bubble, supportive response, no shame vibe"),
    ("assets/images/tracks/genz/scenario_genz_5.png",
     "A young person giving a confident status update in a team meeting, pointing at a progress bar, colleagues listening attentively"),
    ("assets/images/tracks/genz/scenario_genz_6.png",
     "A person receiving critical feedback from a manager across a desk, listening with open posture, feedback notes with improvement arrows"),
    ("assets/images/tracks/genz/scenario_genz_7.png",
     "A person raising their hand in a meeting to share a different opinion, speech bubble with opposing idea, colleagues around a table"),
    ("assets/images/tracks/genz/scenario_genz_8.png",
     "An employee knocking on a manager's open door to ask for feedback, notebook in hand, proactive curious expression"),
    ("assets/images/tracks/genz/scenario_genz_9.png",
     "A junior employee politely declining extra work from a senior colleague, calm no gesture, both showing understanding, workload visible"),
    ("assets/images/tracks/genz/scenario_genz_10.png",
     "Two peers at a desk, one giving constructive feedback to the other about their work, speech bubble with kind critique, collaborative vibe"),
    ("assets/images/tracks/genz/scenario_genz_11.png",
     "A person asking their manager for a deadline extension at a desk, calendar with revised date, honest conversation, manager considering"),
    ("assets/images/tracks/genz/scenario_genz_12.png",
     "A young employee calmly disagreeing with a manager in a one-on-one, respectful hand gesture, manager listening, office setting"),
    ("assets/images/tracks/genz/scenario_genz_13.png",
     "A young professional approaching strangers at a work conference or networking event, badge visible, confident smile, cocktail hour vibe"),
    ("assets/images/tracks/genz/scenario_genz_14.png",
     "A person negotiating their first job offer on the spot with a recruiter at a table, salary number in speech bubble, holding firm"),
    ("assets/images/tracks/genz/scenario_genz_15.png",
     "A young person leading a team meeting at a whiteboard, keeping discussion on track, colleagues engaged, facilitator role, confident stance"),
]

BANNERS = [
    ("assets/images/tracks/career/banner.png",
     "Wide landscape banner: a confident person shaking hands after a successful job interview, bright professional office background, career ladder icon, warm gold and blue tones, celebratory energy"),
    ("assets/images/tracks/social/banner.png",
     "Wide landscape banner: a diverse group of happy people mingling at a social gathering, warm party lights, laughter bubbles, vibrant pink and purple tones, friendly connection vibe"),
    ("assets/images/tracks/stage/banner.png",
     "Wide landscape banner: a confident speaker on a spotlit stage, microphone in hand, audience silhouettes in awe, dramatic teal and gold tones, inspiring public speaking energy"),
    ("assets/images/tracks/anxiety/banner.png",
     "Wide landscape banner: a person taking a deep breath with closed eyes, nervous energy transforming into calm confidence, soft gradient from stormy grey to sunny yellow, courage blooming"),
    ("assets/images/tracks/tough/banner.png",
     "Wide landscape banner: two people sitting across from each other having a mature honest conversation, calm expressions, soft green and warm tones, bridge icon between them, resolution vibe"),
    ("assets/images/tracks/genz/banner.png",
     "Wide landscape banner: a young professional at a modern open-plan office, laptop and coffee, confident casual pose, bright neon accents on clean white background, Gen Z work energy"),
]

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MAX_SIZE = 512  # px — longest side after resize
TARGET_QUALITY = 6  # PNG compress_level (0-9, higher = smaller)
MAX_RETRIES = 3
RETRY_DELAY = 5  # seconds


# ---------------------------------------------------------------------------
# Compression
# ---------------------------------------------------------------------------
def compress_image(path: Path) -> None:
    """Resize to 512x512 max, RGBA, optimized PNG."""
    from PIL import Image

    img = Image.open(path)
    img = img.convert("RGBA")

    # Resize preserving aspect ratio
    if img.width > MAX_SIZE or img.height > MAX_SIZE:
        img.thumbnail((MAX_SIZE, MAX_SIZE), Image.Resampling.LANCZOS)

    # Quantize to reduce palette (keeps transparency)
    try:
        quantized = img.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
        quantized = quantized.convert("RGBA")
        out = quantized
    except Exception:
        out = img

    out.save(path, "PNG", optimize=True, compress_level=TARGET_QUALITY)
    size_kb = path.stat().st_size / 1024
    print(f"  Compressed {path.name}: {size_kb:.1f} KB")


def compress_all(root: Path) -> None:
    """Compress every PNG under root."""
    pngs = sorted(root.rglob("*.png"))
    if not pngs:
        print("No PNGs found to compress.")
        return
    print(f"\nCompressing {len(pngs)} images...")
    for p in pngs:
        compress_image(p)
    total = sum(p.stat().st_size for p in pngs) / 1024
    print(f"\nTotal size: {total:.1f} KB ({len(pngs)} files)")


# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------
def generate_image(client, prompt: str, reference_bytes=None):
    """Call Gemini to generate an image. Returns (PIL Image, raw PNG bytes).
    reference_bytes should be raw PNG bytes for style consistency."""
    from PIL import Image
    from google.genai import types

    full_prompt = STYLE_PREFIX + prompt

    contents: list = []
    if reference_bytes is not None:
        ref_part = types.Part.from_bytes(data=reference_bytes, mime_type="image/png")
        contents.append(ref_part)
        contents.append("Generate an image of the same character in a new pose. " + full_prompt)
    else:
        contents.append(full_prompt)

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.models.generate_content(
                model="gemini-3.1-flash-image-preview",
                contents=contents,
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE", "TEXT"]
                ),
            )

            # Extract image from response parts
            for part in response.parts:
                if part.inline_data is not None:
                    raw = part.inline_data.data
                    return Image.open(io.BytesIO(raw)), raw

            print(f"  Warning: no image in response (attempt {attempt})")
        except Exception as e:
            print(f"  Error (attempt {attempt}/{MAX_RETRIES}): {e}")
            if attempt < MAX_RETRIES:
                time.sleep(RETRY_DELAY * attempt)

    raise RuntimeError(f"Failed to generate image after {MAX_RETRIES} attempts")


def generate_group(
    client,
    items: list[tuple[str, str]],
    root: Path,
    group_name: str,
    use_reference: bool = False,
) -> None:
    """Generate a group of images. If use_reference, the first image is used
    as a reference for subsequent ones (mascot consistency)."""
    total = len(items)
    skipped = sum(1 for rel_path, _ in items if (root / rel_path).exists())
    to_generate = total - skipped

    print(f"\n{'='*60}")
    print(f"  TRACK: {group_name}")
    print(f"  Total: {total}  |  Already done: {skipped}  |  To generate: {to_generate}")
    print(f"{'='*60}")

    if to_generate == 0:
        print("  All images already exist. Skipping.")
        return

    reference_bytes = None
    generated = 0

    for i, (rel_path, prompt) in enumerate(items):
        out_path = root / rel_path
        out_path.parent.mkdir(parents=True, exist_ok=True)

        scenario_name = Path(rel_path).stem  # e.g. scenario_tough_3

        if out_path.exists():
            print(f"  [{i+1}/{total}] SKIP  {scenario_name}")
            if use_reference and i == 0:
                reference_bytes = out_path.read_bytes()
            continue

        generated += 1
        print(f"\n  [{i+1}/{total}] Generating ({generated}/{to_generate}): {scenario_name}")
        print(f"  Prompt: {prompt[:90]}...")

        ref = reference_bytes if use_reference else None

        img, raw_bytes = generate_image(client, prompt, reference_bytes=ref)
        img.save(str(out_path))
        size_kb = out_path.stat().st_size / 1024
        print(f"  DONE  {scenario_name}  ({size_kb:.0f} KB)  [{generated}/{to_generate} generated]")

        # Store first mascot bytes as reference
        if use_reference and i == 0:
            reference_bytes = raw_bytes

        # Rate limit — be polite to the API
        time.sleep(2)

    print(f"\n  Track complete: {group_name}  ({generated} generated, {skipped} skipped)")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(description="Generate app images via Gemini API")
    parser.add_argument("--api-key", help="Gemini API key (or set GEMINI_API_KEY env var)")
    parser.add_argument(
        "--only",
        choices=["categories", "characters", "mascots", "career", "social", "stage", "anxiety", "tough", "genz", "banners", "scenarios"],
        help="Generate only one group",
    )
    parser.add_argument(
        "--compress-only",
        action="store_true",
        help="Skip generation, just compress existing PNGs",
    )
    args = parser.parse_args()

    # Resolve project root (script lives in tools/)
    root = Path(__file__).resolve().parent.parent

    if args.compress_only:
        compress_all(root / "assets" / "images")
        return

    # Resolve API key
    api_key = args.api_key or os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("Error: provide --api-key or set GEMINI_API_KEY env var")
        sys.exit(1)

    from google import genai

    client = genai.Client(api_key=api_key)

    def track(prefix):
        return [s for s in SCENARIOS if f"/{prefix}/" in s[0]]

    groups = {
        "categories": (CATEGORIES, "Categories", False),
        "characters": (CHARACTERS, "Characters", False),
        "mascots": (MASCOTS, "Mascots (with reference)", True),
        "scenarios": (SCENARIOS, "All Scenarios", False),
        "career":  (track("career"),  "Career Confidence", False),
        "social":  (track("social"),  "Social Butterfly",  False),
        "stage":   (track("stage"),   "Stage Ready",       False),
        "anxiety": (track("anxiety"), "Anxiety Buster",    False),
        "tough":   (track("tough"),   "Tough Conversations", False),
        "genz":    (track("genz"),    "Gen Z at Work",     False),
        "banners": (BANNERS, "Track Banners", False),
    }

    if args.only:
        items, name, use_ref = groups[args.only]
        generate_group(client, items, root, name, use_reference=use_ref)
    else:
        for key in ["categories", "characters", "mascots", "scenarios", "banners"]:
            items, name, use_ref = groups[key]
            generate_group(client, items, root, name, use_reference=use_ref)

    # Compress all generated images
    compress_all(root / "assets" / "images")

    # Summary
    pngs = list((root / "assets" / "images").rglob("*.png"))
    print(f"\n{'='*60}")
    print(f"Done! {len(pngs)} images generated.")
    total_kb = sum(p.stat().st_size for p in pngs) / 1024
    print(f"Total size: {total_kb:.1f} KB")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
