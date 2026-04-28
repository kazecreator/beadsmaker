-- Phase 1 seed batch 2 — adds 14 more patterns across all themes/difficulties/sizes.
-- Run this after 20260424_phase1_seed.sql.

insert into patterns (
    id, author_id, author_name, title, pixels, width, height,
    palette, difficulty, theme, status, thumbnail_path,
    save_count, created_at, published_at
) values

-- animals -----------------------------------------------------------------------
(
    'aaaaaaaa-0001-0001-0001-000000000001', null, 'BeadsMaker Team',
    'Mini Penguin',
    '[{"x":7,"y":3,"colorHex":"#1F1F1F"},{"x":8,"y":3,"colorHex":"#1F1F1F"},{"x":6,"y":4,"colorHex":"#1F1F1F"},{"x":7,"y":4,"colorHex":"#F5F5F5"},{"x":8,"y":4,"colorHex":"#F5F5F5"},{"x":9,"y":4,"colorHex":"#1F1F1F"},{"x":6,"y":5,"colorHex":"#1F1F1F"},{"x":7,"y":5,"colorHex":"#F5F5F5"},{"x":8,"y":5,"colorHex":"#F5F5F5"},{"x":9,"y":5,"colorHex":"#1F1F1F"},{"x":7,"y":6,"colorHex":"#F5A623"},{"x":8,"y":6,"colorHex":"#F5A623"},{"x":6,"y":7,"colorHex":"#F5A623"},{"x":9,"y":7,"colorHex":"#F5A623"}]'::jsonb,
    16, 16, ARRAY['#1F1F1F','#F5F5F5','#F5A623'],
    'easy', 'animals', 'published', null,
    37, now() - interval '14 days', now() - interval '13 days'
),
(
    'aaaaaaaa-0002-0002-0002-000000000002', null, 'BeadsMaker Team',
    'Corgi Face',
    '[{"x":5,"y":4,"colorHex":"#E8A44A"},{"x":6,"y":4,"colorHex":"#E8A44A"},{"x":9,"y":4,"colorHex":"#E8A44A"},{"x":10,"y":4,"colorHex":"#E8A44A"},{"x":5,"y":5,"colorHex":"#E8A44A"},{"x":6,"y":5,"colorHex":"#F5D08C"},{"x":7,"y":5,"colorHex":"#F5D08C"},{"x":8,"y":5,"colorHex":"#F5D08C"},{"x":9,"y":5,"colorHex":"#F5D08C"},{"x":10,"y":5,"colorHex":"#E8A44A"},{"x":6,"y":6,"colorHex":"#F5D08C"},{"x":7,"y":6,"colorHex":"#1F1F1F"},{"x":8,"y":6,"colorHex":"#1F1F1F"},{"x":9,"y":6,"colorHex":"#F5D08C"},{"x":7,"y":7,"colorHex":"#C2856B"},{"x":8,"y":7,"colorHex":"#1F1F1F"}]'::jsonb,
    16, 16, ARRAY['#E8A44A','#F5D08C','#C2856B','#1F1F1F'],
    'easy', 'animals', 'published', null,
    55, now() - interval '20 days', now() - interval '19 days'
),

-- food -------------------------------------------------------------------------
(
    'aaaaaaaa-0003-0003-0003-000000000003', null, 'BeadCraft Studio',
    'Ramen Bowl',
    '[{"x":4,"y":5,"colorHex":"#D4824A"},{"x":5,"y":5,"colorHex":"#D4824A"},{"x":6,"y":5,"colorHex":"#D4824A"},{"x":7,"y":5,"colorHex":"#D4824A"},{"x":8,"y":5,"colorHex":"#D4824A"},{"x":9,"y":5,"colorHex":"#D4824A"},{"x":10,"y":5,"colorHex":"#D4824A"},{"x":11,"y":5,"colorHex":"#D4824A"},{"x":4,"y":6,"colorHex":"#F5E8C8"},{"x":11,"y":6,"colorHex":"#F5E8C8"},{"x":5,"y":6,"colorHex":"#FFDDC1"},{"x":6,"y":6,"colorHex":"#E88C6B"},{"x":7,"y":6,"colorHex":"#E88C6B"},{"x":8,"y":6,"colorHex":"#5A9E6F"},{"x":9,"y":6,"colorHex":"#5A9E6F"},{"x":10,"y":6,"colorHex":"#FFDDC1"},{"x":4,"y":7,"colorHex":"#D4824A"},{"x":5,"y":7,"colorHex":"#F5E8C8"},{"x":11,"y":7,"colorHex":"#D4824A"},{"x":6,"y":8,"colorHex":"#D4824A"},{"x":7,"y":8,"colorHex":"#D4824A"},{"x":8,"y":8,"colorHex":"#D4824A"},{"x":9,"y":8,"colorHex":"#D4824A"},{"x":10,"y":8,"colorHex":"#D4824A"}]'::jsonb,
    16, 16, ARRAY['#D4824A','#F5E8C8','#FFDDC1','#E88C6B','#5A9E6F'],
    'medium', 'food', 'published', null,
    48, now() - interval '16 days', now() - interval '15 days'
),
(
    'aaaaaaaa-0004-0004-0004-000000000004', null, 'BeadCraft Studio',
    'Watermelon Wedge',
    '[{"x":4,"y":6,"colorHex":"#E8524A"},{"x":5,"y":5,"colorHex":"#E8524A"},{"x":6,"y":4,"colorHex":"#E8524A"},{"x":7,"y":4,"colorHex":"#E8524A"},{"x":8,"y":4,"colorHex":"#E8524A"},{"x":9,"y":4,"colorHex":"#E8524A"},{"x":10,"y":5,"colorHex":"#E8524A"},{"x":11,"y":6,"colorHex":"#E8524A"},{"x":5,"y":6,"colorHex":"#F57C72"},{"x":6,"y":5,"colorHex":"#F57C72"},{"x":7,"y":5,"colorHex":"#F57C72"},{"x":8,"y":5,"colorHex":"#F57C72"},{"x":9,"y":5,"colorHex":"#F57C72"},{"x":10,"y":6,"colorHex":"#F57C72"},{"x":6,"y":7,"colorHex":"#5DB85D"},{"x":7,"y":7,"colorHex":"#5DB85D"},{"x":8,"y":7,"colorHex":"#5DB85D"},{"x":9,"y":7,"colorHex":"#5DB85D"},{"x":6,"y":5,"colorHex":"#1F1F1F"},{"x":8,"y":6,"colorHex":"#1F1F1F"},{"x":10,"y":5,"colorHex":"#1F1F1F"}]'::jsonb,
    16, 16, ARRAY['#E8524A','#F57C72','#5DB85D','#1F1F1F'],
    'easy', 'food', 'published', null,
    29, now() - interval '9 days', now() - interval '8 days'
),

-- nature -----------------------------------------------------------------------
(
    'aaaaaaaa-0005-0005-0005-000000000005', null, 'MiniMaker',
    'Cherry Blossom',
    '[{"x":6,"y":3,"colorHex":"#FFB7C5"},{"x":9,"y":3,"colorHex":"#FFB7C5"},{"x":7,"y":4,"colorHex":"#FFB7C5"},{"x":8,"y":4,"colorHex":"#FFB7C5"},{"x":6,"y":5,"colorHex":"#FFB7C5"},{"x":7,"y":5,"colorHex":"#FF8FAB"},{"x":8,"y":5,"colorHex":"#FF8FAB"},{"x":9,"y":5,"colorHex":"#FFB7C5"},{"x":7,"y":6,"colorHex":"#FFB7C5"},{"x":8,"y":6,"colorHex":"#FF8FAB"},{"x":7,"y":7,"colorHex":"#6B9E3F"},{"x":8,"y":7,"colorHex":"#6B9E3F"},{"x":7,"y":8,"colorHex":"#6B9E3F"},{"x":7,"y":9,"colorHex":"#8B6E4E"}]'::jsonb,
    16, 16, ARRAY['#FFB7C5','#FF8FAB','#6B9E3F','#8B6E4E'],
    'easy', 'nature', 'published', null,
    62, now() - interval '25 days', now() - interval '24 days'
),

-- games ------------------------------------------------------------------------
(
    'aaaaaaaa-0006-0006-0006-000000000006', null, 'MiniMaker',
    'Pixel Coin',
    '[{"x":7,"y":4,"colorHex":"#FFD700"},{"x":8,"y":4,"colorHex":"#FFD700"},{"x":6,"y":5,"colorHex":"#FFD700"},{"x":7,"y":5,"colorHex":"#FFC200"},{"x":8,"y":5,"colorHex":"#FFC200"},{"x":9,"y":5,"colorHex":"#FFD700"},{"x":6,"y":6,"colorHex":"#FFD700"},{"x":7,"y":6,"colorHex":"#FFED80"},{"x":8,"y":6,"colorHex":"#FFC200"},{"x":9,"y":6,"colorHex":"#FFD700"},{"x":7,"y":7,"colorHex":"#FFD700"},{"x":8,"y":7,"colorHex":"#FFD700"}]'::jsonb,
    16, 16, ARRAY['#FFD700','#FFC200','#FFED80'],
    'easy', 'games', 'published', null,
    33, now() - interval '7 days', now() - interval '6 days'
),
(
    'aaaaaaaa-0007-0007-0007-000000000007', null, 'PixelPusher',
    'Gameboy Sprite',
    '[{"x":4,"y":2,"colorHex":"#8BAC0F"},{"x":5,"y":2,"colorHex":"#8BAC0F"},{"x":6,"y":2,"colorHex":"#8BAC0F"},{"x":7,"y":2,"colorHex":"#8BAC0F"},{"x":8,"y":2,"colorHex":"#8BAC0F"},{"x":9,"y":2,"colorHex":"#8BAC0F"},{"x":10,"y":2,"colorHex":"#8BAC0F"},{"x":11,"y":2,"colorHex":"#8BAC0F"},{"x":4,"y":3,"colorHex":"#8BAC0F"},{"x":5,"y":3,"colorHex":"#306230"},{"x":6,"y":3,"colorHex":"#306230"},{"x":9,"y":3,"colorHex":"#306230"},{"x":10,"y":3,"colorHex":"#306230"},{"x":11,"y":3,"colorHex":"#8BAC0F"},{"x":4,"y":4,"colorHex":"#8BAC0F"},{"x":5,"y":4,"colorHex":"#306230"},{"x":6,"y":4,"colorHex":"#0F380F"},{"x":7,"y":4,"colorHex":"#306230"},{"x":8,"y":4,"colorHex":"#306230"},{"x":9,"y":4,"colorHex":"#0F380F"},{"x":10,"y":4,"colorHex":"#306230"},{"x":11,"y":4,"colorHex":"#8BAC0F"},{"x":5,"y":5,"colorHex":"#306230"},{"x":6,"y":5,"colorHex":"#306230"},{"x":7,"y":5,"colorHex":"#9BBC0F"},{"x":8,"y":5,"colorHex":"#9BBC0F"},{"x":9,"y":5,"colorHex":"#306230"},{"x":10,"y":5,"colorHex":"#306230"},{"x":5,"y":6,"colorHex":"#8BAC0F"},{"x":6,"y":6,"colorHex":"#8BAC0F"},{"x":7,"y":6,"colorHex":"#8BAC0F"},{"x":8,"y":6,"colorHex":"#8BAC0F"},{"x":9,"y":6,"colorHex":"#8BAC0F"},{"x":10,"y":6,"colorHex":"#8BAC0F"}]'::jsonb,
    16, 16, ARRAY['#8BAC0F','#9BBC0F','#306230','#0F380F'],
    'medium', 'games', 'published', null,
    71, now() - interval '30 days', now() - interval '29 days'
),

-- anime ------------------------------------------------------------------------
(
    'aaaaaaaa-0008-0008-0008-000000000008', null, 'PixelPusher',
    'Chibi Eye',
    '[{"x":6,"y":4,"colorHex":"#1F1F1F"},{"x":7,"y":4,"colorHex":"#1F1F1F"},{"x":8,"y":4,"colorHex":"#1F1F1F"},{"x":5,"y":5,"colorHex":"#1F1F1F"},{"x":6,"y":5,"colorHex":"#4A90D9"},{"x":7,"y":5,"colorHex":"#4A90D9"},{"x":8,"y":5,"colorHex":"#1F1F5E"},{"x":9,"y":5,"colorHex":"#1F1F1F"},{"x":5,"y":6,"colorHex":"#1F1F1F"},{"x":6,"y":6,"colorHex":"#6AAEF0"},{"x":7,"y":6,"colorHex":"#FFFFFF"},{"x":8,"y":6,"colorHex":"#1F1F5E"},{"x":9,"y":6,"colorHex":"#1F1F1F"},{"x":6,"y":7,"colorHex":"#1F1F1F"},{"x":7,"y":7,"colorHex":"#1F1F1F"},{"x":8,"y":7,"colorHex":"#1F1F1F"}]'::jsonb,
    16, 16, ARRAY['#1F1F1F','#4A90D9','#1F1F5E','#6AAEF0','#FFFFFF'],
    'medium', 'anime', 'published', null,
    44, now() - interval '11 days', now() - interval '10 days'
),

-- holiday ----------------------------------------------------------------------
(
    'aaaaaaaa-0009-0009-0009-000000000009', null, 'FestiveBeads',
    'Christmas Tree',
    '[{"x":8,"y":2,"colorHex":"#2D7D32"},{"x":7,"y":3,"colorHex":"#2D7D32"},{"x":8,"y":3,"colorHex":"#388E3C"},{"x":9,"y":3,"colorHex":"#2D7D32"},{"x":6,"y":4,"colorHex":"#2D7D32"},{"x":7,"y":4,"colorHex":"#388E3C"},{"x":8,"y":4,"colorHex":"#388E3C"},{"x":9,"y":4,"colorHex":"#388E3C"},{"x":10,"y":4,"colorHex":"#2D7D32"},{"x":5,"y":5,"colorHex":"#2D7D32"},{"x":6,"y":5,"colorHex":"#388E3C"},{"x":7,"y":5,"colorHex":"#FFD700"},{"x":8,"y":5,"colorHex":"#388E3C"},{"x":9,"y":5,"colorHex":"#E53935"},{"x":10,"y":5,"colorHex":"#388E3C"},{"x":11,"y":5,"colorHex":"#2D7D32"},{"x":7,"y":6,"colorHex":"#8B6E4E"},{"x":8,"y":6,"colorHex":"#8B6E4E"},{"x":7,"y":7,"colorHex":"#8B6E4E"},{"x":8,"y":7,"colorHex":"#8B6E4E"},{"x":8,"y":2,"colorHex":"#FFD700"}]'::jsonb,
    16, 16, ARRAY['#2D7D32','#388E3C','#FFD700','#E53935','#8B6E4E'],
    'easy', 'holiday', 'published', null,
    58, now() - interval '18 days', now() - interval '17 days'
),

-- geometric --------------------------------------------------------------------
(
    'aaaaaaaa-0010-0010-0010-000000000010', null, 'FestiveBeads',
    'Diamond Pattern',
    '[{"x":8,"y":2,"colorHex":"#5B9BD5"},{"x":7,"y":3,"colorHex":"#5B9BD5"},{"x":9,"y":3,"colorHex":"#5B9BD5"},{"x":6,"y":4,"colorHex":"#5B9BD5"},{"x":8,"y":4,"colorHex":"#2E75B6"},{"x":10,"y":4,"colorHex":"#5B9BD5"},{"x":5,"y":5,"colorHex":"#5B9BD5"},{"x":7,"y":5,"colorHex":"#2E75B6"},{"x":9,"y":5,"colorHex":"#2E75B6"},{"x":11,"y":5,"colorHex":"#5B9BD5"},{"x":6,"y":6,"colorHex":"#5B9BD5"},{"x":8,"y":6,"colorHex":"#2E75B6"},{"x":10,"y":6,"colorHex":"#5B9BD5"},{"x":7,"y":7,"colorHex":"#5B9BD5"},{"x":9,"y":7,"colorHex":"#5B9BD5"},{"x":8,"y":8,"colorHex":"#5B9BD5"}]'::jsonb,
    16, 16, ARRAY['#5B9BD5','#2E75B6','#BDD7EE'],
    'easy', 'geometric', 'published', null,
    22, now() - interval '4 days', now() - interval '3 days'
),
(
    'aaaaaaaa-0011-0011-0011-000000000011', null, 'GeoArt',
    'Checkerboard Mini',
    '[{"x":4,"y":4,"colorHex":"#1F1F1F"},{"x":6,"y":4,"colorHex":"#1F1F1F"},{"x":8,"y":4,"colorHex":"#1F1F1F"},{"x":10,"y":4,"colorHex":"#1F1F1F"},{"x":5,"y":5,"colorHex":"#1F1F1F"},{"x":7,"y":5,"colorHex":"#1F1F1F"},{"x":9,"y":5,"colorHex":"#1F1F1F"},{"x":11,"y":5,"colorHex":"#1F1F1F"},{"x":4,"y":6,"colorHex":"#1F1F1F"},{"x":6,"y":6,"colorHex":"#1F1F1F"},{"x":8,"y":6,"colorHex":"#1F1F1F"},{"x":10,"y":6,"colorHex":"#1F1F1F"},{"x":5,"y":7,"colorHex":"#1F1F1F"},{"x":7,"y":7,"colorHex":"#1F1F1F"},{"x":9,"y":7,"colorHex":"#1F1F1F"},{"x":11,"y":7,"colorHex":"#1F1F1F"}]'::jsonb,
    16, 16, ARRAY['#1F1F1F','#FFFFFF'],
    'easy', 'geometric', 'published', null,
    17, now() - interval '2 days', now() - interval '1 day'
),

-- emoji ------------------------------------------------------------------------
(
    'aaaaaaaa-0012-0012-0012-000000000012', null, 'GeoArt',
    'Star Sparkle',
    '[{"x":8,"y":3,"colorHex":"#FFD700"},{"x":7,"y":4,"colorHex":"#FFD700"},{"x":8,"y":4,"colorHex":"#FFE066"},{"x":9,"y":4,"colorHex":"#FFD700"},{"x":5,"y":5,"colorHex":"#FFD700"},{"x":6,"y":5,"colorHex":"#FFD700"},{"x":7,"y":5,"colorHex":"#FFE066"},{"x":8,"y":5,"colorHex":"#FFE066"},{"x":9,"y":5,"colorHex":"#FFD700"},{"x":10,"y":5,"colorHex":"#FFD700"},{"x":11,"y":5,"colorHex":"#FFD700"},{"x":7,"y":6,"colorHex":"#FFD700"},{"x":8,"y":6,"colorHex":"#FFE066"},{"x":9,"y":6,"colorHex":"#FFD700"},{"x":6,"y":7,"colorHex":"#FFD700"},{"x":8,"y":7,"colorHex":"#FFD700"},{"x":10,"y":7,"colorHex":"#FFD700"},{"x":7,"y":8,"colorHex":"#FFD700"},{"x":9,"y":8,"colorHex":"#FFD700"},{"x":8,"y":9,"colorHex":"#FFD700"}]'::jsonb,
    16, 16, ARRAY['#FFD700','#FFE066','#FFA500'],
    'easy', 'emoji', 'published', null,
    39, now() - interval '13 days', now() - interval '12 days'
),

-- fantasy (medium, larger canvas) ----------------------------------------------
(
    'aaaaaaaa-0013-0013-0013-000000000013', null, 'DreamPixel',
    'Moon & Stars',
    '[{"x":8,"y":3,"colorHex":"#F5E6CA"},{"x":9,"y":3,"colorHex":"#F5E6CA"},{"x":7,"y":4,"colorHex":"#F5E6CA"},{"x":10,"y":4,"colorHex":"#F5E6CA"},{"x":11,"y":5,"colorHex":"#F5E6CA"},{"x":10,"y":6,"colorHex":"#F5E6CA"},{"x":9,"y":7,"colorHex":"#F5E6CA"},{"x":8,"y":7,"colorHex":"#F5E6CA"},{"x":7,"y":6,"colorHex":"#F5E6CA"},{"x":4,"y":4,"colorHex":"#F5E6CA"},{"x":12,"y":3,"colorHex":"#F5E6CA"},{"x":5,"y":9,"colorHex":"#F5E6CA"},{"x":14,"y":8,"colorHex":"#F5E6CA"},{"x":3,"y":12,"colorHex":"#F5E6CA"},{"x":11,"y":11,"colorHex":"#F5E6CA"},{"x":7,"y":14,"colorHex":"#F5E6CA"}]'::jsonb,
    20, 20, ARRAY['#F5E6CA','#C9B8E8','#2C2C54'],
    'medium', 'fantasy', 'published', null,
    46, now() - interval '22 days', now() - interval '21 days'
),

-- other (hard, large canvas) ---------------------------------------------------
(
    'aaaaaaaa-0014-0014-0014-000000000014', null, 'DreamPixel',
    'Sunset Gradient',
    '[{"x":4,"y":4,"colorHex":"#FF6B35"},{"x":5,"y":4,"colorHex":"#FF6B35"},{"x":6,"y":4,"colorHex":"#FF8C42"},{"x":7,"y":4,"colorHex":"#FF8C42"},{"x":8,"y":4,"colorHex":"#FFA559"},{"x":9,"y":4,"colorHex":"#FFA559"},{"x":10,"y":4,"colorHex":"#FFC175"},{"x":11,"y":4,"colorHex":"#FFC175"},{"x":4,"y":5,"colorHex":"#FF8C42"},{"x":5,"y":5,"colorHex":"#FFA559"},{"x":6,"y":5,"colorHex":"#FFC175"},{"x":7,"y":5,"colorHex":"#FFD59C"},{"x":8,"y":5,"colorHex":"#FFD59C"},{"x":9,"y":5,"colorHex":"#FFC175"},{"x":10,"y":5,"colorHex":"#FFA559"},{"x":11,"y":5,"colorHex":"#FF8C42"},{"x":4,"y":6,"colorHex":"#7B5EA7"},{"x":5,"y":6,"colorHex":"#9B7DC8"},{"x":6,"y":6,"colorHex":"#C4A8E8"},{"x":7,"y":6,"colorHex":"#C4A8E8"},{"x":8,"y":6,"colorHex":"#C4A8E8"},{"x":9,"y":6,"colorHex":"#C4A8E8"},{"x":10,"y":6,"colorHex":"#9B7DC8"},{"x":11,"y":6,"colorHex":"#7B5EA7"},{"x":4,"y":7,"colorHex":"#3D3580"},{"x":5,"y":7,"colorHex":"#5550A0"},{"x":6,"y":7,"colorHex":"#7B5EA7"},{"x":7,"y":7,"colorHex":"#9B7DC8"},{"x":8,"y":7,"colorHex":"#9B7DC8"},{"x":9,"y":7,"colorHex":"#7B5EA7"},{"x":10,"y":7,"colorHex":"#5550A0"},{"x":11,"y":7,"colorHex":"#3D3580"}]'::jsonb,
    16, 16, ARRAY['#FF6B35','#FF8C42','#FFA559','#FFC175','#FFD59C','#7B5EA7','#9B7DC8','#C4A8E8','#3D3580','#5550A0'],
    'hard', 'other', 'published', null,
    19, now() - interval '1 day', now() - interval '1 day'
)

on conflict (id) do update set
    author_name   = excluded.author_name,
    title         = excluded.title,
    pixels        = excluded.pixels,
    width         = excluded.width,
    height        = excluded.height,
    palette       = excluded.palette,
    difficulty    = excluded.difficulty,
    theme         = excluded.theme,
    status        = excluded.status,
    thumbnail_path = excluded.thumbnail_path,
    save_count    = excluded.save_count,
    created_at    = excluded.created_at,
    published_at  = excluded.published_at;

-- Add some recent saves for the new patterns to give them non-zero week_save_count.
insert into saves (pattern_id, device_id, saved_at) values
-- Corgi (popular, all recent)
('aaaaaaaa-0002-0002-0002-000000000002', 'seed-b2-01', now() - interval '1 day'),
('aaaaaaaa-0002-0002-0002-000000000002', 'seed-b2-02', now() - interval '2 days'),
('aaaaaaaa-0002-0002-0002-000000000002', 'seed-b2-03', now() - interval '3 days'),
('aaaaaaaa-0002-0002-0002-000000000002', 'seed-b2-04', now() - interval '4 days'),
('aaaaaaaa-0002-0002-0002-000000000002', 'seed-b2-05', now() - interval '5 days'),
-- Gameboy Sprite (high weekly)
('aaaaaaaa-0007-0007-0007-000000000007', 'seed-b2-06', now() - interval '1 day'),
('aaaaaaaa-0007-0007-0007-000000000007', 'seed-b2-07', now() - interval '2 days'),
('aaaaaaaa-0007-0007-0007-000000000007', 'seed-b2-08', now() - interval '3 days'),
-- Cherry Blossom
('aaaaaaaa-0005-0005-0005-000000000005', 'seed-b2-09', now() - interval '2 days'),
('aaaaaaaa-0005-0005-0005-000000000005', 'seed-b2-10', now() - interval '4 days'),
-- Christmas Tree
('aaaaaaaa-0009-0009-0009-000000000009', 'seed-b2-11', now() - interval '1 day'),
('aaaaaaaa-0009-0009-0009-000000000009', 'seed-b2-12', now() - interval '3 days'),
-- Pixel Coin
('aaaaaaaa-0006-0006-0006-000000000006', 'seed-b2-13', now() - interval '2 days'),
-- Diamond Pattern
('aaaaaaaa-0010-0010-0010-000000000010', 'seed-b2-14', now() - interval '1 day'),
-- Penguin
('aaaaaaaa-0001-0001-0001-000000000001', 'seed-b2-15', now() - interval '5 days'),
('aaaaaaaa-0001-0001-0001-000000000001', 'seed-b2-16', now() - interval '6 days'),
-- Moon & Stars
('aaaaaaaa-0013-0013-0013-000000000013', 'seed-b2-17', now() - interval '1 day'),
('aaaaaaaa-0013-0013-0013-000000000013', 'seed-b2-18', now() - interval '3 days'),
('aaaaaaaa-0013-0013-0013-000000000013', 'seed-b2-19', now() - interval '6 days')
on conflict (pattern_id, device_id) do update set
    saved_at = excluded.saved_at;
