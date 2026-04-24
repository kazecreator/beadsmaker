-- patterns_explore view
-- Joins published patterns with a 7-day save count so PostgREST can
-- sort by weekly popularity server-side (no client-side aggregation needed).

CREATE OR REPLACE VIEW patterns_explore AS
SELECT
    p.id,
    p.title,
    p.author_name,
    p.width,
    p.height,
    p.pixels,
    p.palette,
    p.difficulty,
    p.theme,
    p.status,
    p.thumbnail_path,
    p.save_count,
    p.created_at,
    p.published_at,
    p.size_tier,
    COALESCE(w.week_save_count, 0) AS week_save_count
FROM patterns p
LEFT JOIN (
    SELECT
        pattern_id,
        COUNT(*)::int AS week_save_count
    FROM saves
    WHERE saved_at >= NOW() - INTERVAL '7 days'
    GROUP BY pattern_id
) w ON p.id = w.pattern_id
WHERE p.status = 'published';

-- Grant read access to anonymous and authenticated PostgREST roles.
-- The view's WHERE clause already enforces the published-only boundary.
GRANT SELECT ON patterns_explore TO anon, authenticated;
